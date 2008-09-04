
module Rake ; end

require 'rake/comptree/driver'

module Rake
  module TaskManager
    # :nodoc:
    def invoke_parallel_tasks
      parent_names = parallel_tasks.keys.map { |name|
        name.to_sym
      }

      root_name = "computation_root__#{Process.pid}__#{rand}".to_sym
         
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
        parallel_tasks.each_pair { |task_name, task_args|
          task = self[task_name]
          children_names = task.prerequisites.map { |child|
            child.to_sym
          }
          driver.define(task_name.to_sym, *children_names) {
            task.execute(task_args)
          }
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
        driver.compute(root_name, :threads => num_threads, :fork => false)
      }
    end
  end
end
