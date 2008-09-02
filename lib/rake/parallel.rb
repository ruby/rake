
module Rake
end

require 'rake/comptree/driver'

module Rake
  class Application
    # :nodoc:
    def invoke_tasks_parallel(parsed_tasks, num_threads, use_fork)
      parent_names = parsed_tasks.keys.map { |name|
        name.to_sym
      }

      root_name = "computation_root__#{Process.pid}".to_sym
         
      CompTree::Driver.new(:discard_result => true) { |driver|

        #
        # Define the root computation node.
        #
        # Top-level tasks are immediate children of the root.
        #
        driver.define(root_name, *parent_names) {
        }
        
        #
        # build the rest of the computation tree from task prereqs
        #
        tasks.each { |task|
          if task.needed?
            children_names = task.prerequisites.map { |child|
              Task[child] # check if child exists
              child.to_sym
            }
            
            task_args =
              if args = parsed_tasks[task.name]
                TaskArguments.new(task.arg_names, args)
              else
                {}
              end
            
            driver.define(task.name.to_sym, *children_names) {
              task.execute(task_args)
            }
          end
        }
        
        #
        # Mark computation nodes without a function as computed.
        #
        driver.nodes[root_name].each_downward { |node|
          unless node.function
            node.result = true
          end
        }
        
        #
        # launch the computation
        #
        driver.compute(
          root_name,
          :threads => num_threads,
          :fork => use_fork)
      }
    end
  end
end
