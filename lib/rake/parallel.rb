
module Rake ; end

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

        create_node = lambda { |task, task_args|
          if task.needed?
            # grab task args from the first invocation only
            node_name = task.name.to_sym
            node = driver.node(node_name)
            unless node and node.function
              children_names = task.prerequisites.map { |child|
                child.to_sym
              }
              driver.define(node_name, *children_names) {
                unless task.already_invoked
                  task.already_invoked = true
                  task.execute(task_args)
                end
              }
            end
          end
        }

        create_node_recursive = lambda { |task, task_args|
          create_node.call(task, task_args)
          prereq_names = task.prerequisites
          unless prereq_names.empty?
            prereq_names.each { |prereq_name|
              prereq_task = Rake::Task[prereq_name]
              create_node_recursive.call(
                prereq_task,
                task_args.new_scope(prereq_task.arg_names))
            }
          end
        }

        parsed_tasks.each_pair { |task_name, task_args|
          create_node_recursive.call(Rake::Task[task_name], task_args)
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
