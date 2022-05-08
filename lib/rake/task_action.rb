# frozen_string_literal: true
module Rake

  ##
  # A TaskAction represents each action of a task.
  #
  class TaskAction
    attr_reader :results

    def initialize(&block)
      @block = block
      @results = []
    end

    def call(argc, argv, opts)
      results << call_block(argc, argv, opts)
    rescue => error
      results << error
      raise error
    end

    private

    def call_block(argc, argv, opts)
      if opts && !opts.empty?
        @block.call(argc, argv, **opts)
      else
        @block.call(argc, argv)
      end
    end
  end
end
