require 'thread'
require 'set'

module Rake

  class ThreadPool

    # Creates a ThreadPool object.
    # The parameter is the size of the pool.
    def initialize(thread_count)
      @max_thread_count = [thread_count, 0].max
      @threads = Set.new
      @threads_mon = Monitor.new
      @queue = Queue.new
      @join_cond = @threads_mon.new_cond
    end

    # Creates a future executed by the +ThreadPool+.
    # The args are passed to the block when executing (similarly to <tt>Thread#new</tt>)
    # The return value is an object representing a future which has been created and
    # added to the queue in the pool. Sending <tt>#value</tt> to the object will sleep
    # the current thread until the future is finished and will return the result (or
    # raise an exception thrown from the future)
    def future(*args,&block)
      # capture the local args for the block (like Thread#start)
      local_args = args.collect { |a| begin; a.dup; rescue; a; end }

      promise_mutex = Mutex.new
      promise_result = promise_error = NOT_SET

      # (promise code builds on Ben Lavender's public-domain 'promise' gem)
      promise = lambda do
        # return immediately if the future has been executed
        unless promise_result.equal?(NOT_SET) && promise_error.equal?(NOT_SET)
          return promise_error.equal?(NOT_SET) ? promise_result : raise(promise_error)
        end

        # try to get the lock and execute the promise, otherwise, sleep.
        if promise_mutex.try_lock
          if promise_result.equal?(NOT_SET) && promise_error.equal?(NOT_SET)
            #execute the promise
            begin
              promise_result = block.call(*local_args)
            rescue Exception => e
              promise_error = e
            end
            block = local_args = nil # GC can now clean these up
          end
          promise_mutex.unlock
        else
          # Even if we didn't get the lock, we need to sleep until the promise has
          # finished executing. If, however, the current thread is part of the thread
          # pool, we need to free up a new thread in the pool so there will
          # always be a thread doing work.

          wait_for_promise = lambda { promise_mutex.synchronize{} }

          unless @threads_mon.synchronize { @threads.include? Thread.current }
            wait_for_promise.call
          else
            @threads_mon.synchronize { @max_thread_count += 1 }
            start_thread
            wait_for_promise.call
            @threads_mon.synchronize { @max_thread_count -= 1 }
          end
        end
        promise_error.equal?(NOT_SET) ? promise_result : raise(promise_error)
      end

      def promise.value
        call
      end

      @queue.enq promise
      start_thread
      promise
    end

    # Waits until the queue of futures is empty and all threads have exited.
    def join
      @threads_mon.synchronize do
        begin
            @join_cond.wait unless @threads.empty?
        rescue Exception => e
          $stderr.puts e
          $stderr.print "Queue contains #{@queue.size} items. Thread pool contains #{@threads.count} threads\n"
          $stderr.print "Current Thread #{Thread.current} status = #{Thread.current.status}\n"
          $stderr.puts e.backtrace.join("\n")
          @threads.each do |t|
            $stderr.print "Thread #{t} status = #{t.status}\n"
            $stderr.puts t.backtrace.join("\n") if t.respond_to? :backtrace
          end
          raise e
        end
      end
    end

  private
    def start_thread # :nodoc:
      @threads_mon.synchronize do
        next unless @threads.count < @max_thread_count

        @threads << Thread.new do
          begin
            while @threads.count <= @max_thread_count && !@queue.empty? do
              # Even though we just asked if the queue was empty,
              # it still could have had an item which by this statement is now gone.
              # For this reason we pass true to Queue#deq because we will sleep
              # indefinitely if it is empty.
              @queue.deq(true).call
            end
          rescue ThreadError # this means the queue is empty
          ensure
            @threads_mon.synchronize do
              @threads.delete Thread.current
              @join_cond.broadcast if @threads.empty?
            end
          end
        end
      end
    end

    # for testing only

    def __queue__ # :nodoc:
      @queue
    end

    def __threads__ # :nodoc:
      @threads.dup
    end

    NOT_SET = Object.new.freeze # :nodoc:
  end

end
