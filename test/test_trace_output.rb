# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)
require "stringio"

class TestTraceOutput < Rake::TestCase # :nodoc:
  include Rake::TraceOutput

  class PrintSpy # :nodoc:
    attr_reader :result, :calls

    def initialize
      @result = "".dup
      @calls = 0
    end

    def print(string)
      @result << string
      @calls += 1
    end
  end

  def test_trace_issues_single_io_for_args_with_empty_args
    spy = PrintSpy.new
    trace_on(spy)
    assert_equal "\n", spy.result
    assert_equal 1, spy.calls
  end

  def test_trace_issues_single_io_for_args_multiple_strings
    spy = PrintSpy.new
    trace_on(spy, "HI\n", "LO")
    assert_equal "HI\nLO\n", spy.result
    assert_equal 1, spy.calls
  end

  def test_trace_handles_nil_objects
    spy = PrintSpy.new
    trace_on(spy, "HI\n", nil, "LO")
    assert_equal "HI\nLO\n", spy.result
    assert_equal 1, spy.calls
  end

  def test_trace_issues_single_io_for_args_multiple_strings_and_alternate_sep
    verbose, $VERBOSE = $VERBOSE, nil
    old_sep = $\
    $\ = "\r"
    $VERBOSE = verbose
    spy = PrintSpy.new
    trace_on(spy, "HI\r", "LO")
    assert_equal "HI\rLO\r", spy.result
    assert_equal 1, spy.calls
  ensure
    $VERBOSE = nil
    $\ = old_sep
    $VERBOSE = verbose
  end
end
