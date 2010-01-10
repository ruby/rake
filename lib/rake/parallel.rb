#
# Parallel task execution for Rake.
#
# The comp_tree package is used to create a computation tree which
# executes Rake tasks.
#
# Tasks are first collected with a single-threaded dry run.  This
# expands file rules, resolves prequisite names and finds task
# arguments.  A computation tree is then built with the gathered
# tasks.
#
# Note that prerequisites are context-dependent.  It is therefore not
# possible to create a 1-to-1 mapping between Rake::Tasks and
# CompTree::Nodes.
#
# Author: James M. Lawrence <quixoticsycophant@gmail.com>
#

require 'comp_tree'

module Rake
  module Parallel  #:nodoc:
    class Driver
      # Tasks collected during the dry-run phase.
      attr_reader :tasks

      # Prevent invoke inside invoke.
      attr_reader :mutex

      def initialize
        @tasks = Hash.new
        @mutex = Mutex.new
      end

      #
      # Top-level parallel invocation.
      #
      # Called from Task#invoke (routed through Task#invoke_parallel).
      #
      def invoke(threads, task, *task_args)
        if @mutex.try_lock
          begin
            @tasks.clear

            # dry run task collector
            task.invoke_serial(*task_args)

            if @tasks.has_key? task
              # hand it off to comp_tree
              compute(task, threads)
            end
          ensure
            @mutex.unlock
          end
        else
          raise InvokeInsideInvoke
        end
      end

      #
      # Build and run the computation tree.
      #
      # Called from Parallel::Driver#invoke.
      #
      def compute(root_task, threads)
        CompTree.build do |driver|
          # keep this around for optimization
          needed_prereq_names = Array.new

          @tasks.each_pair do |task, (task_args, prereqs)|
            needed_prereq_names.clear

            prereqs.each do |prereq|
              # if a prereq is not needed then it didn't get into @tasks
              if @tasks.has_key? prereq
                needed_prereq_names << prereq.name
              end
            end

            # define a computation node which executes the task
            driver.define(task.name, *needed_prereq_names) {
              task.execute(task_args)
            }
          end

          # punch it
          driver.compute(root_task.name, threads)
        end
      end
    end
  
    module ApplicationMixin
      def parallel
        @parallel ||= Driver.new
      end
    end

    module TaskMixin
      #
      # Top-level parallel invocation.
      #
      # Called from Task#invoke.
      #
      def invoke_parallel(*task_args)
        application.parallel.
          invoke(application.options.threads, self, *task_args)
      end

      #
      # Collect tasks for parallel execution.
      #
      # Called from Task#invoke_with_call_chain.
      #
      def invoke_with_call_chain_collector(task_args, new_chain, previous_chain)
        prereqs = invoke_prerequisites_collector(task_args, new_chain)
        parallel = application.parallel
        if needed? or parallel.tasks[self]
          parallel.tasks[self] = [task_args, prereqs]
          unless previous_chain == InvocationChain::EMPTY
            #
            # Touch the parent to propagate 'needed?' upwards.  This
            # works because the recursion is depth-first.
            #
            parallel.tasks[previous_chain.value] = true
          end
        end
      end
      
      #
      # Dry-run invoke prereqs and return the prereq instances.
      # This also serves to avoid MultiTask#invoke_prerequisites.
      #
      # Called from Task#invoke_with_call_chain_collector.
      #
      def invoke_prerequisites_collector(task_args, invocation_chain)
        prerequisite_tasks.map { |prereq|
          invoke_prerequisite(prereq, task_args, invocation_chain)
        }
      end
    end
  end

  #
  # Error indicating Task#invoke was called inside Task#invoke
  # during parallel execution.
  #
  class InvokeInsideInvoke < StandardError
    def message
      "Cannot call Task#invoke within a task during parallel execution."
    end
  end
end
