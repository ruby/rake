#!/usr/bin/env ruby

module Rake
  class TestTask
    attr_accessor :name, :libs, :pattern, :verbose

    def initialize(name=:test)
      @name = name
      @libs = ["lib"]
      @pattern = 'test/test*.rb'
      @verbose = false
      yield self if block_given?
    end

    def define
      lib_path = @libs.join(':')
      desc "Run tests" + (@name==:test ? "" : " for #{@name}")
      task @name do
	ruby %{-I#{lib_path} -rrake/runtest -e 'Rake.run_tests("#{@pattern}", #{@verbose})'}
      end
    end

  end
end

