
require 'comp_tree/diagnostic'
require 'comp_tree/retriable_fork'

module CompTree
  module Algorithm
    include Diagnostic

    def compute_multithreaded(root, num_threads, use_fork, buckets)
      trace "Computing #{root.name} with #{num_threads} threads"
      result = nil
      tree_mutex = Mutex.new
      node_finished_condition = ConditionVariable.new
      thread_wake_condition = ConditionVariable.new
      threads = []
      
      num_threads.times { |thread_index|
        threads << Thread.new {
          #
          # wait for main thread
          #
          tree_mutex.synchronize {
            trace "Thread #{thread_index} waiting to start"
            thread_wake_condition.wait(tree_mutex)
          }

          while true
            trace "Thread #{thread_index} node search"

            #
            # Done! Thread will exit.
            #
            break if tree_mutex.synchronize {
              result
            }

            #
            # Lock the tree and find a node.  The node we
            # obtain, if any, is already locked.
            #
            node = tree_mutex.synchronize {
              find_node(root)
            }

            if node
              trace "Thread #{thread_index} found node #{node.name}"

              node_result =
                compute_node(
                  node,
                  use_fork,
                  buckets ? buckets[thread_index] : nil)
              
              tree_mutex.synchronize {
                node.result = node_result
              }

              #
              # remove locks for this node (shared lock and own lock)
              #
              tree_mutex.synchronize {
                node.unlock
                if node == root
                  #
                  # Root node was computed; we are done.
                  #
                  trace "Thread #{thread_index} got final answer"
                  result = root.result
                end
                node_finished_condition.signal
              }
            else
              trace "Thread #{thread_index}: no node found; sleeping."
              tree_mutex.synchronize {
                thread_wake_condition.wait(tree_mutex)
              }
            end
          end
          trace "Thread #{thread_index} exiting"
        }
      }

      trace "Main: waiting for threads to launch and block."
      while true
        break if tree_mutex.synchronize {
          Thread.list.all? { |t|
            t == Thread.current or t.status == "sleep"
          }
        }
        Thread.pass
      end
      
      trace "Main: entering main loop"
      tree_mutex.synchronize {
        while true
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
      catch(:done) {
        while true
          tree_mutex.synchronize {
            throw :done if threads.all? { |thread|
              thread.status == false
            }
            thread_wake_condition.broadcast
          }
          Thread.pass
        end
      }

      trace "Main: computation done."
      result
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
      elsif node.children_results and node.try_lock
        #
        # Node is not computed and its children are computed;
        # and we have the lock.  Ready to compute.
        #
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
        trace "About to fork for node #{node.name}"
        if bucket
          #
          # Use our assigned bucket to transfer the result.
          #
          fork_node(node) {
            node.trace_compute
            bucket.contents = node.compute
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
        node.trace_compute
        node.compute
      end
    end

    def fork_node(node)
      trace "About to fork for node #{node.name}"
      process_id = RetriableFork.fork {
        trace "Fork: process #{Process.pid}"
        node.trace_compute
        yield
        trace "Fork: computation done"
      }
      trace "Waiting for process #{process_id}"
      Process.wait(process_id)
      trace "Process #{process_id} finished"
      exitstatus = $?.exitstatus
      if exitstatus != 0
        trace "Process #{process_id} returned #{exitstatus}; exiting."
        exit(1)
      end
    end
    
    extend self
  end
end
