
require 'comp_tree/diagnostic'
require 'comp_tree/retriable_fork'
require 'comp_tree/misc'

module CompTree
  module Algorithm
    include Diagnostic
    include Misc
    include RetriableFork

    def compute_multithreaded(root, num_threads, use_fork, buckets)
      trace "Computing #{root.name} with #{num_threads} threads"

      result = nil

      tree_mutex = Mutex.new
      node_finished_condition = ConditionVariable.new
      thread_wake_condition = ConditionVariable.new
      num_threads_in_use = 0

      threads = (0...num_threads).map { |thread_index|
        Thread.new {
          #
          # wait for main thread
          #
          tree_mutex.synchronize {
            trace "Thread #{thread_index} waiting to start"
            num_threads_in_use += 1
            thread_wake_condition.wait(tree_mutex)
          }

          loop_with(:done, :restart) {
            node = tree_mutex.synchronize {
              trace "Thread #{thread_index} node search"
              if result
                trace "Thread #{thread_index} detected finish"
                num_threads_in_use -= 1
                throw :done
              else
                #
                # Lock the tree and find a node.
                # The node we obtain, if any, will be locked.
                #
                if node = find_node(root)
                  trace(
                    "Thread #{thread_index} found node #{node.name}; " +
                    "ready to compute"
                  )
                  node
                else
                  trace "Thread #{thread_index}: no node found; sleeping."
                  thread_wake_condition.wait(tree_mutex)
                  throw :restart
                end
              end
            }

            trace "Thread #{thread_index} computing node"
            node_result = compute_node(
              node,
              use_fork,
              buckets ? buckets[thread_index] : nil
            )
            trace "Thread #{thread_index} node computed; waiting for tree lock"

            tree_mutex.synchronize {
              trace "Thread #{thread_index} acquired tree lock"
              debug {
                name = "#{node.name}" + ((node == root) ? " (ROOT NODE)" : "")
                initial = "Thread #{thread_index} compute result for #{name}: "
                status = node_result.is_a?(Exception) ? "error" : "success"
                trace initial + status
                trace "Thread #{thread_index} node result: #{node_result}"
              }

              node.result = node_result

              #
              # remove locks for this node (shared lock and own lock)
              #
              node.unlock

              if node == root or node_result.is_a? Exception
                #
                # Root node was computed; we are done.
                #
                result = node.result
              end
                
              #
              # Tell the main thread that another node was computed.
              #
              node_finished_condition.signal
            }
          }
          trace "Thread #{thread_index} exiting"
        }
      }

      trace "Main: waiting for threads to launch and block."
      until tree_mutex.synchronize { num_threads_in_use == num_threads }
        Thread.pass
      end

      tree_mutex.synchronize {
        trace "Main: entering main loop"
        until num_threads_in_use == 0
          trace "Main: waking threads"
          thread_wake_condition.broadcast

          if result
            trace "Main: detected finish."
            break
          end

          trace "Main: waiting for a node"
          node_finished_condition.wait(tree_mutex)
          trace "Main: got a node"
        end
      }

      trace "Main: waiting for threads to finish."
      loop_with(:done, :restart) {
        tree_mutex.synchronize {
          if threads.all? { |thread| thread.status == false }
            throw :done
          end
          thread_wake_condition.broadcast
        }
        Thread.pass
      }

      trace "Main: computation done."
      if result.is_a? Exception
        raise result
      else
        result
      end
    end

    def find_node(node)
      # --- only called inside shared tree mutex
      trace "Looking for a node, starting with #{node.name}"
      if node.result
        #
        # already computed
        #
        trace "#{node.name} has been computed"
        nil
      elsif (children_results = node.find_children_results) and node.try_lock
        #
        # Node is not computed and its children are computed;
        # and we have the lock.  Ready to compute.
        #
        node.children_results = children_results
        node
      else
        #
        # locked or children not computed; recurse to children
        #
        trace "Checking #{node.name}'s children"
        node.each_child { |child|
          if next_node = find_node(child)
            return next_node
          end
        }
        nil
      end
    end

    def compute_node(node, use_fork, bucket)
      if use_fork
        if bucket
          #
          # Use our assigned bucket to transfer the result.
          #
          fork_node(node) {
            node.trace_compute
            bucket.contents = (
              begin 
                node.compute
              rescue Exception => e
                e
              end
            )
          }
          bucket.contents
        else
          #
          # No bucket -- discarding result
          #
          fork_node(node) {
            node.trace_compute
            node.compute
          }
          true
        end
      else
        #
        # No fork
        #
        begin
          node.trace_compute
          node.compute
        rescue Exception => e
          e
        end
      end
    end

    def fork_node(node)
      trace "About to fork for node #{node.name}"
      process_id = 123456
      process_id = fork {
        trace "Fork: process #{Process.pid}"
        node.trace_compute
        yield
        trace "Fork: computation done"
      }
      trace "Waiting for process #{process_id}"
      Process.wait(process_id)
      trace "Process #{process_id} finished"
      trace "Process #{process_id} returned #{$?.exitstatus}"
    end
    
    extend self
  end
end
