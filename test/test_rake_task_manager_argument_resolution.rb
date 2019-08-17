# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeTaskManagerArgumentResolution < Rake::TestCase # :nodoc:

  def test_good_arg_patterns
    assert_equal [:t, [], [], nil],       task(:t)
    assert_equal [:t, [], [:x], nil],     task(t: :x)
    assert_equal [:t, [], [:x, :y], nil], task(t: [:x, :y])

    assert_equal [:t, [:a, :b], [], nil],       task(:t, [:a, :b])
    assert_equal [:t, [:a, :b], [:x], nil],     task(:t, [:a, :b] => :x)
    assert_equal [:t, [:a, :b], [:x, :y], nil], task(:t, [:a, :b] => [:x, :y])
  end

  def task(*args)
    tm = Rake::TestCase::TaskManager.new
    tm.resolve_args(args)
  end
end
