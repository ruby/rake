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

    # True if verbose test output desired. (default is false)
    attr_accessor :verbose

    # Glob pattern to match test files. (default is 'test/test*.rb')
    attr_accessor :pattern

    # Explicitly define the list of test files to be included in a
    # test.  +list+ is expected to be an array of file names (a
    # FileList is acceptable).  If both +pattern+ and +test_files+ are
    # used, then the list of test files is the union of the two.
    def test_files=(list)
      @test_files = list
    end

    # Create a testing task.
    def initialize(name=:test)
      @name = name
      @libs = ["lib"]
      @pattern = nil
      @test_files = nil
      @verbose = false
      yield self if block_given?
      @pattern = 'test/test*.rb' if @pattern.nil? && @test_files.nil?
      define
    end

    # Create the tasks defined by this task lib.
    def define
      lib_path = @libs.join(':')
      if ENV['TESTOPTS']
	testoptions = " \\\n -- #{ENV['TESTOPTS']}"
      else
	testoptions = ''
      end
      desc "Run tests" + (@name==:test ? "" : " for #{@name}")
      task @name do
	testreqs = test_file_list.gsub(/^(.*)\.rb$/, ' -r\1').join(" \\\n")
	RakeFileUtils.verbose(@verbose) do
	  ruby %{-I#{lib_path} -e0 \\\n#{testreqs}#{testoptions}}
	end
      end
      self
    end

    def test_file_list
      if ENV['TEST']
	FileList[ ENV['TEST'] ]
      else
	result = []
	result += @test_files.to_a if @test_files
	result += FileList[ @pattern ].to_a if @pattern
	FileList[result]
      end
    end

  end
end

