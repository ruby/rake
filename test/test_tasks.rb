#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'rake'
require 'test/filecreation'
require 'test/capture_stdout'

######################################################################
class TestTask < Test::Unit::TestCase
  include CaptureStdout
  include Rake

  def setup
    Task.clear
  end

  def test_create
    arg = nil
    t = intern(:name).enhance { |task| arg = task; 1234 }
    assert_equal "name", t.name
    assert_equal [], t.prerequisites
    assert t.prerequisites.is_a?(FileList)
    assert t.needed?
    t.execute
    assert_equal t, arg
    assert_nil t.source
    assert_equal [], t.sources
    assert_equal [], t.args
  end

  def test_invoke
    runlist = []
    t1 = intern(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = intern(:t2).enhance { |t| runlist << t.name }
    t3 = intern(:t3).enhance { |t| runlist << t.name }
    assert_equal [:t2, :t3], t1.prerequisites
    t1.invoke
    assert_equal ["t2", "t3", "t1"], runlist
  end

  def test_dry_run_prevents_actions
    Rake.application.options.dryrun = true
    runlist = []
    t1 = intern(:t1).enhance { |t| runlist << t.name; 3321 }
    out = capture_stdout { t1.invoke }
    assert_match(/execute .*t1/i, out)
    assert_match(/dry run/i, out)
    assert_no_match(/invoke/i, out)
    assert_equal [], runlist
  ensure
    Rake.application.options.dryrun = false
  end

  def test_tasks_can_be_traced
    Rake.application.options.trace = true
    t1 = intern(:t1) { |t| runlist << t.name; 3321 }
    out = capture_stdout {
      t1.invoke
    }
    assert_match(/invoke t1/i, out)
    assert_match(/execute t1/i, out)
  ensure
    Rake.application.options.trace = false
  end

  def test_no_double_invoke
    runlist = []
    t1 = intern(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = intern(:t2).enhance([:t3]) { |t| runlist << t.name }
    t3 = intern(:t3).enhance { |t| runlist << t.name }
    t1.invoke
    assert_equal ["t3", "t2", "t1"], runlist
  end

  def test_find
    task :tfind
    assert_equal "tfind", Task[:tfind].name
    ex = assert_raises(RuntimeError) { Task[:leaves] }
    assert_equal "Don't know how to build task 'leaves'", ex.message
  end

  def test_defined
    assert ! Task.task_defined?(:a)
    task :a
    assert Task.task_defined?(:a)
  end

  def test_multi_invocations
    runs = []
    p = proc do |t| runs << t.name end
    task({:t1=>[:t2,:t3]}, &p)
    task({:t2=>[:t3]}, &p)
    task(:t3, &p)
    Task[:t1].invoke
    assert_equal ["t1", "t2", "t3"], runs.sort
  end

  def test_task_list
    task :t2
    task :t1 => [:t2]
    assert_equal ["t1", "t2"], Task.tasks.collect {|t| t.name}
  end

  def test_task_gives_name_on_to_s
    task :abc
    assert_equal "abc", Task[:abc].to_s
  end

  def test_symbols_can_be_prerequisites
    task :a => :b
    assert_equal ["b"], Task[:a].prerequisites
  end

  def test_strings_can_be_prerequisites
    task :a => "b"
    assert_equal ["b"], Task[:a].prerequisites
  end

  def test_arrays_can_be_prerequisites
    task :a => ["b", "c"]
    assert_equal ["b", "c"], Task[:a].prerequisites
  end

  def test_filelists_can_be_prerequisites
    task :a => FileList.new.include("b", "c")
    assert_equal ["b", "c"], Task[:a].prerequisites
  end

  def test_investigation_output
    t1 = intern(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    intern(:t2)
    intern(:t3)
    out = t1.investigation
    assert_match(/class:\s*Rake::Task/, out)
    assert_match(/needed:\s*true/, out)
    assert_match(/pre-requisites:\s*--t2/, out)
  end
  
  def test_tasks_can_access_arguments
    t = intern(:t1).enhance { |t| 
      a, b, c = t.args
      assert_equal 1, a
      assert_equal 2, b
      assert_equal 3, c
    }
    t.args = [1, 2, 3]
    t.invoke
  end

  private

  def intern(name)
    Rake.application.define_task(Rake::Task,name)
  end

end

