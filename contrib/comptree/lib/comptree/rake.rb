#
# = comptree/rake -- Execute Rake Tasks in Parallel.
#
# == Synopsis
#
# Run three simultaneous threads:
#    $ rake -r comptree 3
#
# Run three simultaneous threads, with each task forked into a new
# process:
#
#    $ rake -r comptree 3!
#
# == Important Note
#
# In a given Rakefile, it is possible (even likely) that the
# dependency tree has not been properly defined.  Consider
#
#    task :a => [:x, :y, :z]
#
# With single-threaded +rake+, _x_,_y_,_z_ will be invoked <em>in that
# order</em> before _a_ is invoked.  However with <code>rake -r
# comptree N</code>, one should not expect any particular order of
# execution.  Since there is no dependency specified between
# _x_,_y_,_z_ above, <code>comptree</code> is free to execute them in
# any order.
#
# If you wish _x_,_y_,_z_ to be invoked sequentially, then write
#
#    task :a => seq[:x, :y, :z]
#
# This is shorthand for
#
#    task :a => :z
#    task :z => :y
#    task :y => :x
#
# Upon invoking _a_, the above rules say: "Can't do _a_ until _z_ is
# complete; can't do _z_ until _y_ is complete; can't do _y_ until _x_
# is complete; therefore do _x_."  In this fashion the sequence
# _x_,_y_,_z_ is enforced.
#
# == License
# 
# <code>comptree/rake.rb</code> and the +CompTree+ module are
# copyright (c) 2008 James M.  Lawrence.  It is free software, and is
# distributed under the Ruby license. See the COPYING file in the
# standard Ruby distribution for details.
# 
# 
# == Warranty
# 
# This software is provided "as is" and without any express or
# implied warranties, including, without limitation, the implied
# warranties of merchantability and fitness for a particular
# purpose.
# 
# 
# == Author
# 
# James M. Lawrence.
# Copyright (c) 2008, James M. Lawrence
#

require 'comptree' #:nodoc:

module Rake #:nodoc:
  class Application #:nodoc:
    alias_method :top_level__original, :top_level

    def top_level #:nodoc:
      num_threads, use_fork =
        if @top_level_tasks.first and
            (match = @top_level_tasks.first.match(/\A(\d+)(!?)\Z/))
          @top_level_tasks.shift
          if @top_level_tasks.empty?
            @top_level_tasks = [:default]
          end
          [match.captures[0].to_i, (match.captures[1] == "!")]
        else
          [1, false]
        end

      if num_threads == 1
        top_level__original
      else
        parent_tasks = @top_level_tasks

        #
        # Trick top_level__original into not invoking tasks
        #
        @top_level_tasks = []
        top_level__original

        standard_exception_handling {
          invoke_parallelized(num_threads, use_fork, parent_tasks)
        }
      end
    end

    def invoke_parallelized(num_threads, use_fork, parent_tasks) #:nodoc:
      #
      # MultiTask ignores the dependency tree --- nuke it.
      #
      # We happen to not be calling this anyway, however this is an
      # accident waiting to happen.
      #
      MultiTask.class_eval {
        remove_method :invoke_prerequisites
      }
      
      parent_args = parent_tasks.inject(Hash.new) { |acc, task_string|
        name, args = parse_task_string(task_string)
        acc.update(name => args)
      }

      parent_names = parent_args.keys.map { |name|
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
        driver.compute(root_name, :threads => num_threads, :fork => use_fork)
      }
    end
  end
end

#
# use this form to cleanly hide the lambda
#
(class << self ; self ; end).class_eval {
  seq_lambda = lambda { |*task_names|
    (1...task_names.size).each { |n|
      task task_names[n] => task_names[n - 1]
    }
    task_names.last
  }
  
  define_method(:seq) {
    seq_lambda
  }
}
