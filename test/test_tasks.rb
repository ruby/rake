#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'rake'
require 'test/filecreation'
require 'test/capture_stdout'


module Interning
  private

  def intern(name, *args)
    Rake.application.define_task(Rake::Task, name, *args)
  end
end

######################################################################
class TestTask < Test::Unit::TestCase
  include CaptureStdout
  include Rake
  include Interning

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
    t.execute(0)
    assert_equal t, arg
    assert_nil t.source
    assert_equal [], t.sources
  end

  def test_inspect
    t = intern(:foo).enhance([:bar, :baz])
    assert_equal "<Rake::Task foo => [bar, baz]>", t.inspect
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

  def test_invoke_with_circular_dependencies
    runlist = []
    t1 = intern(:t1).enhance([:t2]) { |t| runlist << t.name; 3321 }
    t2 = intern(:t2).enhance([:t1]) { |t| runlist << t.name }
    assert_equal [:t2], t1.prerequisites
    assert_equal [:t1], t2.prerequisites
    ex = assert_raise RuntimeError do
      t1.invoke
    end
    assert_match(/circular dependency/i, ex.message)
    assert_match(/t1 => t2 => t1/, ex.message)
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


  def test_extended_comments
    desc %{
      This is a comment.

      And this is the extended comment.
      name -- Name of task to execute.
      rev  -- Software revision to use.
    }
    t = intern(:t, :name, :rev)
    assert_equal "[name,rev]", t.arg_description
    assert_equal "This is a comment.", t.comment
    assert_match(/^\s*name -- Name/, t.full_comment)
    assert_match(/^\s*rev  -- Software/, t.full_comment)
    assert_match(/\A\s*This is a comment\.$/, t.full_comment)
  end

  def test_multiple_comments
    desc "line one"
    t = intern(:t)
    desc "line two"
    intern(:t)
    assert_equal "line one / line two", t.comment
  end

  def test_settable_comments
    t = intern(:t)
    t.comment = "HI"
    assert_equal "HI", t.comment
  end
end

######################################################################
class TestTaskWithArguments < Test::Unit::TestCase
  include CaptureStdout
  include Rake
  include Interning

  def setup
    Task.clear
  end

  def test_no_args_given
    t = task :t
    assert_equal [], t.arg_names
  end

  def test_args_given
    t = task :t, :a, :b
    assert_equal [:a, :b], t.arg_names
  end

  def test_name_and_needs
    t = task(:t => [:pre])
    assert_equal "t", t.name
    assert_equal [], t.arg_names
    assert_equal ["pre"], t.prerequisites
  end

  def test_name_and_explicit_needs
    t = task(:t, :needs => [:pre])
    assert_equal "t", t.name
    assert_equal [], t.arg_names
    assert_equal ["pre"], t.prerequisites
  end

  def test_name_args_and_explicit_needs
    t = task(:t, :x, :y, :needs => [:pre])
    assert_equal "t", t.name
    assert_equal [:x, :y], t.arg_names
    assert_equal ["pre"], t.prerequisites
  end

  def test_illegal_keys_in_task_name_hash
    assert_raise RuntimeError do
      t = task(:t, :x, :y => 1, :needs => [:pre])
    end
  end

  def test_arg_list_is_empty_if_no_args_given
    t = intern(:t).enhance do |tt, args|
      assert_equal({}, args.to_hash)
    end
    t.invoke(1, 2, 3)
  end

  def test_tasks_can_access_arguments_as_hash
    t = task :t, :a, :b, :c do |tt, args|
      assert_equal({:a => 1, :b => 2, :c => 3}, args.to_hash)
      assert_equal 1, args[:a]
      assert_equal 2, args[:b]
      assert_equal 3, args[:c]
      assert_equal 1, args.a
      assert_equal 2, args.b
      assert_equal 3, args.c
    end
    t.invoke(1, 2, 3)
  end

  def test_actions_of_various_arity_are_ok_with_args
    notes = []
    t = intern(:t, :x).enhance do
      notes << :a
    end
    t.enhance do | |
      notes << :b
    end
    t.enhance do |task|
      notes << :c
      assert_kind_of Task, task
    end
    t.enhance do |t2, args|
      notes << :d
      assert_equal t, t2
      assert_equal({:x => 1}, args.to_hash)
    end
    assert_nothing_raised do t.invoke(1) end
    assert_equal [:a, :b, :c, :d], notes
  end

  def test_arguments_are_passed_to_block
    t = intern(:t, :a, :b).enhance { |tt, args|
      assert_equal( { :a => 1, :b => 2 }, args.to_hash )
    }
    t.invoke(1, 2)
  end

  def test_extra_parameters_are_ignored
    t = intern(:t, :a).enhance { |tt, args|
      assert_equal 1, args.a
      assert_nil args[2]
    }
    t.invoke(1, 2)
  end

  def test_arguments_are_passed_to_all_blocks
    counter = 0
    t = task :t, :a
    task :t do |tt, args|
      assert_equal 1, args.a
      counter += 1
    end
    task :t do |tt, args|
      assert_equal 1, args.a
      counter += 1
    end
    t.invoke(1)
    assert_equal 2, counter
  end

  def test_block_with_no_parameters_is_ok
    t = intern(:t).enhance { }
    t.invoke(1, 2)
  end

  def test_name_with_args
    desc "T"
    t = intern(:tt, :a, :b)
    assert_equal "tt", t.name
    assert_equal "T", t.comment
    assert_equal "[a,b]", t.arg_description
    assert_equal "tt[a,b]", t.name_with_args
    assert_equal [:a, :b],t.arg_names
  end

  def test_named_args_are_passed_to_prereqs
    value = nil
    pre = intern(:pre, :rev).enhance { |t, args| value = args.rev }
    t = intern(:t, :name, :rev).enhance([:pre])
    t.invoke("bill", "1.2")
    assert_equal "1.2", value
  end

  def test_args_not_passed_if_no_prereq_names
    pre = intern(:pre).enhance { |t, args|
      assert_equal({}, args.to_hash)
      assert_equal "bill", args.name
    }
    t = intern(:t, :name, :rev).enhance([:pre])
    t.invoke("bill", "1.2")
  end

  def test_args_not_passed_if_no_arg_names
    pre = intern(:pre, :rev).enhance { |t, args|
      assert_equal({ :rev => nil }, args.to_hash)
    }
    t = intern(:t).enhance([:pre])
    t.invoke("bill", "1.2")
  end
end
