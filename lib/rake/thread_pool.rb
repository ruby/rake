require 'thread'
require 'set'

module Rake

  class ThreadPool              # :nodoc: all

    # Creates a ThreadPool object.
    # The parameter is the size of the pool.
    def initialize(thread_count)
      @max_active_threads = [thread_count, 0].max
      @threads = Set.new
      @threads_mon = Monitor.new
      @queue = Queue.new
      @join_cond = @threads_mon.new_cond

      @history_start_time = nil
      @history = []
      @history_mon = Monitor.new
      @total_threads_in_play = 0
    end

    # Creates a future executed by the +ThreadPool+.
    #
    # The args are passed to the block when executing (similarly to
    # <tt>Thread#new</tt>) The return value is an object representing
    # a future which has been created and added to the queue in the
    # pool. Sending <tt>#value</tt> to the object will sleep the
    # current thread until the future is finished and will return the
    # result (or raise an exception thrown from the future)
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
          # Even if we didn't get the lock, we need to sleep until the
          # promise has finished executing. If, however, the current
          # thread is part of the thread pool, we need to free up a
          # new thread in the pool so there will always be a thread
          # doing work.

          wait_for_promise = lambda {
            stat :waiting, item_id: promise.object_id
            promise_mutex.synchronize {}
            stat :continue, item_id: promise.object_id
          }

          unless @threads_mon.synchronize { @threads.include? Thread.current }
            wait_for_promise.call
          else
            @threads_mon.synchronize { @max_active_threads += 1 }
            start_thread
            wait_for_promise.call
            @threads_mon.synchronize { @max_active_threads -= 1 }
          end
        end
        promise_error.equal?(NOT_SET) ? promise_result : raise(promise_error)
      end

      def promise.value
        call
      end

      @queue.enq promise
      stat :item_queued, item_id: promise.object_id
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

    # Enable the gathering of history events.
    def gather_history          #:nodoc:
      @history_start_time = Time.now if @history_start_time.nil?
    end

    # Return a array of history events for the thread pool.
    #
    # History gathering must be enabled to be able to see the events
    # (see #gather_history). Best to call this when the job is
    # complete (i.e. after ThreadPool#join is called).
    def history                 # :nodoc:
      @history_mon.synchronize { @history.dup }.sort_by { |item| item[:time] }
    end

    # Return a hash of always collected statistics for the thread pool.
    def statistics              #  :nodoc:
      {
        total_threads_in_play: @total_threads_in_play,
        max_active_threads: @max_active_threads,
      }
    end

    private

    def start_thread # :nodoc:
      @threads_mon.synchronize do
        next unless @threads.count < @max_active_threads

        t = Thread.new do
          begin
            while @threads.count <= @max_active_threads && !@queue.empty? do
              # Even though we just asked if the queue was empty, it
              # still could have had an item which by this statement
              # is now gone. For this reason we pass true to Queue#deq
              # because we will sleep indefinitely if it is empty.
              block = @queue.deq(true)
              stat :item_dequeued, item_id: block.object_id
              block.call
            end
          rescue ThreadError # this means the queue is empty
          ensure
            @threads_mon.synchronize do
              @threads.delete Thread.current
              stat :thread_deleted, deleted_thread: Thread.current.object_id, thread_count: @threads.count
              @join_cond.broadcast if @threads.empty?
            end
          end
        end
        @threads << t
        stat :thread_created, new_thread: t.object_id, thread_count: @threads.count
        @total_threads_in_play = @threads.count if @threads.count > @total_threads_in_play
      end
    end

    def stat(event, data=nil) # :nodoc:
      return if @history_start_time.nil?
      info = {
        event: event,
        data: data,
        time: (Time.now-@history_start_time),
        thread: Thread.current.object_id,
      }
      @history_mon.synchronize { @history << info }
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
