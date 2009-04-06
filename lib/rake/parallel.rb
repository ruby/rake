
require 'rake/comp_tree/comp_tree'

module Rake
  module TaskManager
    def invoke_parallel(root_task_name) # :nodoc:
      CompTree.build do |driver|
        #
        # Build the computation tree from task prereqs.
        #
        self.parallel.tasks.each_pair { |task_name, cache|
          task = self[task_name]
          task_args, prereqs = cache
          children_names = prereqs.map { |child| child.name }
          driver.define(task_name, *children_names) {
            task.execute(task_args)
            true
          }
        }

        root_node = driver.nodes[root_task_name]

        #
        # If there were nothing to do, there would be no root node.
        #
        if root_node
          #
          # Mark computation nodes without a function as computed.
          #
          root_node.each_downward { |node|
            unless node.function
              node.result = true
            end
          }

          #
          # Launch the computation.
          #
          driver.compute(root_node.name, self.num_threads)
        end
      end
    end
  end
end
