# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeTaskArgumentParsing < Rake::TestCase # :nodoc:
  def setup
    super

    @app = Rake::Application.new
  end

  def test_results_with_a_simple_task_and_a_single_invocation
    task = Rake::Task.new("simple", @app)

    task.enhance(nil) { "result" }
    task.invoke

    assert_equal ["result"], task.results
  end

  def test_results_with_a_simple_task_and_multiple_invocations
    task = Rake::Task.new("simple", @app)

    task.enhance(nil) { "result" }
    task.invoke
    task.reenable
    task.invoke

    assert_equal ["result", "result"], task.results
  end

  def test_results_with_a_composite_task_and_a_single_invocation
    task = Rake::Task.new("composite", @app)

    task.enhance(nil) { "result1" }
    task.enhance(nil) { "result2" }
    task.invoke

    assert_equal ["result1", "result2"], task.results
  end

  def test_results_with_a_composite_task_and_multiple_invocations
    task = Rake::Task.new("composite", @app)

    task.enhance(nil) { "result1" }
    task.enhance(nil) { "result2" }

    task.invoke
    task.reenable
    task.invoke

    assert_equal ["result1", "result1", "result2", "result2"], task.results
  end

  def test_results_with_an_empty_task
    task = Rake::Task.new("empty", @app)
    task.invoke

    assert task.results.empty?
  end

  def test_results_with_a_composite_task_and_no_invocations
    task = Rake::Task.new("composite", @app)

    task.enhance(nil) { "result1" }
    task.enhance(nil) { "result2" }

    assert task.results.empty?
  end
end
