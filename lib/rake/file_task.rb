# frozen_string_literal: true
require "rake/task"
require "rake/early_time"

module Rake

  # A FileTask is a task that includes time based dependencies.  If any of a
  # FileTask's prerequisites have a timestamp that is later than the file
  # represented by this task, then the file must be rebuilt (using the
  # supplied actions).
  #
  class FileTask < Task

    # Is this file task needed?  Yes if it doesn't exist, or if its time stamp
    # is out of date.
    def needed?
      begin
        @application.options.build_all || out_of_date?(File.mtime(name))
      rescue Errno::ENOENT
        true
      end
    end

    # Time stamp for file task.
    def timestamp
      begin
        File.mtime(name)
      rescue Errno::ENOENT
        Rake::LATE
      end
    end

    private

    # Are there any prerequisites with a later time than the given time stamp?
    def out_of_date?(stamp)
      all_prerequisite_tasks.any? { |prereq|
        prereq_task = application[prereq, @scope]
        prereq_task.timestamp > stamp
      }
    end

    # ----------------------------------------------------------------
    # Task class methods.
    #
    class << self
      # Apply the scope to the task name according to the rules for this kind
      # of task.  File based tasks ignore the scope when creating the name.
      def scope_name(scope, task_name)
        Rake.from_pathname(task_name)
      end
    end
  end
end
