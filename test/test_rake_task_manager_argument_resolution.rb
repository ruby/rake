require File.expand_path('../helper', __FILE__)

class TestRakeTaskManagerArgumentResolution < Rake::TestCase

  def test_good_arg_patterns
    assert_equal [:t, [], [], []],       task(:t)
    assert_equal [:t, [], [:x], []],     task(:t => :x)
    assert_equal [:t, [], [:x, :y], []], task(:t => [:x, :y])

    assert_equal [:t, [:a, :b], [], []],       task(:t, [:a, :b])
    assert_equal [:t, [:a, :b], [:x], []],     task(:t, [:a, :b] => :x)
    assert_equal [:t, [:a, :b], [:x, :y], []], task(:t, [:a, :b] => [:x, :y])

    assert_equal [:t, [], [], [:tr]],       task(:t, :triggers => :tr)
    assert_equal [:t, [], [:x], [:tr]],     task(:t => :x, :triggers => :tr)
    assert_equal [:t, [], [:x, :y], [:tr]], task(:t => [:x, :y], :triggers => :tr)

    assert_equal [:t, [:a, :b], [], [:tr]],       task(:t, [:a, :b], :triggers => :tr)
    assert_equal [:t, [:a, :b], [:x], [:tr]],     task(:t, [:a, :b] => :x, :triggers => :tr)
    assert_equal [:t, [:a, :b], [:x, :y], [:tr]], task(:t, [:a, :b] => [:x, :y], :triggers => :tr)

    assert_equal [:t, [], [], [:tr1, :tr2]],       task(:t, :triggers => [:tr1, :tr2])
    assert_equal [:t, [], [:x], [:tr1, :tr2]],     task(:t => :x, :triggers => [:tr1, :tr2])
    assert_equal [:t, [], [:x, :y], [:tr1, :tr2]], task(:t => [:x, :y], :triggers => [:tr1, :tr2])

    assert_equal [:t, [:a, :b], [], [:tr1, :tr2]],       task(:t, [:a, :b], :triggers => [:tr1, :tr2])
    assert_equal [:t, [:a, :b], [:x], [:tr1, :tr2]],     task(:t, [:a, :b] => :x, :triggers => [:tr1, :tr2])
    assert_equal [:t, [:a, :b], [:x, :y], [:tr1, :tr2]], task(:t, [:a, :b] => [:x, :y], :triggers => [:tr1, :tr2])
  end

  def task(*args)
    tm = Rake::TestCase::TaskManager.new
    tm.resolve_args(args)
  end
end
