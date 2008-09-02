
module Rake
end

require 'rake/comptree/driver'

module Rake
  class Application
    # :nodoc:
    def top_level_parallel(num_threads, use_fork)
      parent_tasks = @top_level_tasks
      
      # Trick top_level into not invoking tasks
      @top_level_tasks = []
      
      top_level
      
      invoke_parallel(parent_tasks, num_threads, use_fork)
    end
    
    # :nodoc:
    def invoke_parallel(parent_tasks, num_threads, use_fork)
      parent_args = parent_tasks.inject(Hash.new) { |acc, task_string|
        name, args = parse_task_string(task_string)
        acc.update(name => args)
      }

      parent_names = parent_args.keys.map { |name|
        name.to_sym
      }

      root_name = :"computation_root__#{Process.pid}"
         
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
              child.to_sym
            }
            
            task_args =
              if args = parent_args[task.name]
                TaskArguments.new(task.arg_names, args)
              else
                []
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
