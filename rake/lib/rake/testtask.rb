#!/usr/bin/env ruby

# Define a task library for running unit tests.

require 'rake'
require 'rake/tasklib'

module Rake

  # Create a task that runs a set of tests.
  #
  # Example:
  #  
  #   Rake::TestTask.new do |t|
  #     t.libs << "test"
  #     t.pattern = '*test.rb'
  #     t.verbose = true
  #   end
  #
  class TestTask < TaskLib

    # Name of test task. (default is :test)
    attr_accessor :name

    # List of directories to added to $LOAD_PATH before running the
    # tests. (default is 'lib')
    attr_accessor :libs

    # Glob pattern to match test files. (default is 'test/test*.rb')
    attr_accessor :pattern

    # True if verbose test output desired. (default is false)
    attr_accessor :verbose

    # Create a testing task.
    def initialize(name=:test)
      @name = name
      @libs = ["lib"]
      @pattern = 'test/test*.rb'
      @verbose = false
      yield self if block_given?
      define
    end

    # Create the tasks defined by this task lib.
    def define
      lib_path = @libs.join(':')
      setup_code = running_as_gem ?
        %{-e 'require "rubygems"; require_gem "rake"' } :
	""
      desc "Run tests" + (@name==:test ? "" : " for #{@name}")
      task @name do
	testname = ENV['TESTNAME'] || @pattern
	ruby %{-I#{lib_path} } + setup_code +
	  %{-e 'require "rake/runtest"' } +	  
	  %{-e 'Rake.run_tests("#{testname}", #{@verbose||verbose})'}
      end
      self
    end

    def running_as_gem
      $LOAD_PATH.find { |fn| fn =~ %r{gems/.*/rake} } != nil
    end

  end
end

