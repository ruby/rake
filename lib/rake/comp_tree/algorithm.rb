
module Rake end
module Rake::CompTree
  module Algorithm
    module_function

    def loop_with(leave, again)
      catch(leave) {
        while true
          catch(again) {
            yield
          }
        end
      }
    end

    def compute_multithreaded(root, num_threads)
      #trace "Computing #{root.name} with #{num_threads} threads"
      finished = nil
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
            #trace "Thread #{thread_index} waiting to start"
            num_threads_in_use += 1
            thread_wake_condition.wait(tree_mutex)
          }

          loop_with(:leave, :again) {
            node = tree_mutex.synchronize {
              #trace "Thread #{thread_index} acquired tree lock; begin search"
              if finished
                #trace "Thread #{thread_index} detected finish"
                num_threads_in_use -= 1
                throw :leave
              else
                #
                # Find a node.  The node we obtain, if any, will be locked.
                #
                node = find_node(root)
                if node
                  #trace "Thread #{thread_index} found node #{node.name}"
                  node
                else
                  #trace "Thread #{thread_index}: no node found; sleeping."
                  thread_wake_condition.wait(tree_mutex)
                  throw :again
                end
              end
            }

            #trace "Thread #{thread_index} computing node"
            #debug {
            #  node.trace_compute
            #}
            node.compute
            #trace "Thread #{thread_index} node computed; waiting for tree lock"

            tree_mutex.synchronize {
              #trace "Thread #{thread_index} acquired tree lock"
              #debug {
              #  name = "#{node.name}" + ((node == root) ? " (ROOT NODE)" : "")
              #  initial = "Thread #{thread_index} compute result for #{name}: "
              #  status = node.computed.is_a?(Exception) ? "error" : "success"
              #  trace initial + status
              #  trace "Thread #{thread_index} node result: #{node.result}"
              #}

              if node.computed.is_a? Exception
                #
                # An error occurred; we are done.
                #
                finished = node.computed
              elsif node == root
                #
                # Root node was computed; we are done.
                #
                finished = true
              end
                
              #
              # remove locks for this node (shared lock and own lock)
              #
              node.unlock

              #
              # Tell the main thread that another node was computed.
              #
              node_finished_condition.signal
            }
          }
          #trace "Thread #{thread_index} exiting"
        }
      }

      #trace "Main: waiting for threads to launch and block."
      until tree_mutex.synchronize { num_threads_in_use == num_threads }
        Thread.pass
      end

      tree_mutex.synchronize {
        #trace "Main: entering main loop"
        until num_threads_in_use == 0
          #trace "Main: waking threads"
          thread_wake_condition.broadcast

          if finished
            #trace "Main: detected finish."
            break
          end

          #trace "Main: waiting for a node"
          node_finished_condition.wait(tree_mutex)
          #trace "Main: got a node"
        end
      }

      #trace "Main: waiting for threads to finish."
      loop_with(:leave, :again) {
        tree_mutex.synchronize {
          if threads.all? { |thread| thread.status == false }
            throw :leave
          end
          thread_wake_condition.broadcast
        }
        Thread.pass
      }

      #trace "Main: computation done."
      if finished.is_a? Exception
        raise finished
      else
        root.result
      end
    end

    def find_node(node)
      # --- only called inside shared tree mutex
      #trace "Looking for a node, starting with #{node.name}"
      if node.computed
        #
        # already computed
        #
        #trace "#{node.name} has been computed"
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
        #trace "Checking #{node.name}'s children"
        node.each_child { |child|
          next_node = find_node(child) and return next_node
        }
        nil
      end
    end
  end
end
