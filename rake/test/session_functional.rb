#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'

# Version 2.1.9 of session has a bug where the @debug instance
# variable is not initialized, causing warning messages.  This snippet
# of code fixes that problem.
module Session
  class AbstractSession
    alias old_initialize initialize
    def initialize(*args)
      @debug = nil
      old_initialize(*args)
    end
  end
end

class FunctionalTest < Test::Unit::TestCase
  def setup
    @rake_path = File.expand_path("bin/rake")
    lib_path = File.expand_path("lib")
    @ruby_options = "-I#{lib_path} -I."
    @verbose = ! ENV['VERBOSE'].nil?
  end

  def test_rake_default
    Dir.chdir("test/data/default") do rake end
    assert_match(/^DEFAULT$/, @out)
    assert_status
  end

  def test_rake_error_on_bad_task
    Dir.chdir("test/data/default") do rake "xyz" end
    assert_match(/rake aborted/, @out)
    assert_status(1)
  end

  def test_env_availabe_at_top_scope
    Dir.chdir("test/data/default") do rake "TESTTOPSCOPE=1" end
    assert_match(/^TOPSCOPE$/, @out)
    assert_status
  end

  def test_env_availabe_at_task_scope
    Dir.chdir("test/data/default") do rake "TESTTASKSCOPE=1 task_scope" end
    assert_match(/^TASKSCOPE$/, @out)
    assert_status
  end

  def test_multi_desc
    Dir.chdir("test/data/multidesc") do rake "-T" end
    assert_match %r{^rake a *# A / A2 *$}, @out
    assert_match %r{^rake b *# B *$}, @out
    assert_no_match %r{^rake c}, @out
  end

  def test_rbext
    Dir.chdir("test/data/rbext") do rake "-N" end
    assert_match %r{^OK$}, @out
  end

  def test_nosearch
    Dir.chdir("test/data/nosearch") do rake "-N" end
    assert_match %r{^No Rakefile found}, @out
  end

  def test_dry_run
    Dir.chdir("test/data/default") do rake "-n", "other" end
    assert_match %r{Execute \(dry run\) default}, @out
    assert_match %r{Execute \(dry run\) other}, @out
    assert_no_match %r{DEFAULT}, @out
    assert_no_match %r{OTHER}, @out
  end

  # Test for the trace/dry_run bug found by Brian Chandler
  def test_dry_run_bug
    Dir.chdir("test/data/dryrun") do rake end
    FileUtils.rm_f "test/data/dryrun/temp_one"
    Dir.chdir("test/data/dryrun") do rake "--dry-run" end
    assert_no_match(/No such file/, @out)
    assert_status
  end

  # Test for the trace/dry_run bug found by Brian Chandler
  def test_trace_bug
    Dir.chdir("test/data/dryrun") do rake end
    FileUtils.rm_f "test/data/dryrun/temp_one"
    Dir.chdir("test/data/dryrun") do rake "--trace" end
    assert_no_match(/No such file/, @out)
    assert_status
  end

  def test_imports
    open("test/data/imports/static_deps", "w") do |f|
      f.puts 'puts "STATIC"'
    end
    FileUtils.rm_f "test/data/imports/dynamic_deps"
    Dir.chdir("test/data/imports") do rake end
    assert File.exist?("test/data/imports/dynamic_deps"),
      "'dynamic_deps' file should exist"
    assert_match(/^FIRST$\s+^DYNAMIC$\s+^STATIC$\s+^OTHER$/, @out)
    assert_status
    FileUtils.rm_f "test/data/imports/dynamic_deps"
    FileUtils.rm_f "test/data/imports/static_deps"
  end

  def test_rules_chaining_to_file_task
    remove_chaining_files
    Dir.chdir("test/data/chains") do rake end
    assert File.exist?("test/data/chains/play.app"),
      "'play.app' file should exist"
    assert_status
    remove_chaining_files
  end

  private

  def remove_chaining_files
    %w(play.scpt play.app base).each do |fn|
      FileUtils.rm_f File.join("test/data/chains", fn)
    end
  end

  def rake(*option_list)
    options = option_list.join(' ')
    shell = Session::Shell.new
    command = "ruby #{@ruby_options} #{@rake_path} #{options}"
    puts "COMMAND: [#{command}]" if @verbose
    @out, @err = shell.execute command
    @status = shell.exit_status
    puts "STATUS:  [#{@status}]" if @verbose
    puts "OUTPUT:  [#{@out}]" if @verbose
    puts "ERROR:   [#{@err}]" if @verbose
    puts "PWD:     [#{Dir.pwd}]" if @verbose
    shell.close
  end

  def assert_status(expected_status=0)
    assert_equal expected_status, @status
  end

end
