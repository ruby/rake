# frozen_string_literal: true

module Rake

  ##
  # Options used by the Rake command line application.
  #
  class Options
    attr_accessor :always_multitask
    attr_accessor :backtrace
    attr_accessor :build_all
    attr_accessor :dryrun
    attr_accessor :ignore_deprecate
    attr_accessor :ignore_system
    attr_accessor :job_stats
    attr_accessor :load_system
    attr_accessor :nosearch
    attr_accessor :rakelib
    attr_accessor :show_all_tasks
    attr_accessor :show_prereqs
    attr_accessor :show_task_pattern
    attr_accessor :show_tasks
    attr_accessor :silent
    attr_accessor :suppress_backtrace_pattern
    attr_accessor :thread_pool_size
    attr_accessor :trace
    attr_accessor :trace_output
    attr_accessor :trace_rules
  end

end
