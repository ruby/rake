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
  #     t.test_files = FileList['test/test*.rb']
  #     t.verbose = true
  #   end
  #
  # If rake is invoked with a "TEST=filename" command line option,
  # then the list of test files will be overridden to include only the
  # filename specified on the command line.  This provides an easy way
  # to run just one test.
  #
  # If rake is invoked with a "TESTOPTS=options" command line option,
  # then the given options are passed to the test process after a
  # '--'.  This allows Test::Unit options to be passed to the test
  # suite.
  #
  # Examples:
  #
  #   rake test                           # run tests normally
  #   rake test TEST=just_one_file.rb     # run just one test file.
  #   rake test TESTOPTS="-v"             # run in verbose mode
  #   rake test TESTOPTS="--runner=fox"   # use the fox test runner
  #
  class TestTask < TaskLib

    # Name of test task. (default is :test)
    attr_accessor :name

    # List of directories to added to $LOAD_PATH before running the
    # tests. (default is 'lib')
    attr_accessor :libs

    # True if verbose test output desired. (default is false)
    attr_accessor :verbose

    # Test options passed to the test suite.  An explicit
    # TESTOPTS=opts on the command line will override this. (default
    # is NONE)
    attr_accessor :options

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
      @options = nil
      @test_files = nil
      @verbose = false
      yield self if block_given?
      @pattern = 'test/test*.rb' if @pattern.nil? && @test_files.nil?
      define
    end

    # Create the tasks defined by this task lib.
    def define
      lib_path = @libs.join(File::PATH_SEPARATOR)
      desc "Run tests" + (@name==:test ? "" : " for #{@name}")
      task @name do
	RakeFileUtils.verbose(@verbose) do
	  ruby %{-I#{lib_path} -S testrb #{file_list.join(' ')} #{option_list}}
	end
      end
      self
    end

    def option_list # :nodoc:
      ENV['TESTOPTS'] || @options || ""
    end

    def file_list # :nodoc:
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

