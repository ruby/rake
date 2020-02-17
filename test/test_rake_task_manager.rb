# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeTaskManager < Rake::TestCase # :nodoc:

  def setup
    super

    @tm = Rake::TestCase::TaskManager.new
  end

  def test_create_task_manager
    refute_nil @tm
    assert_equal [], @tm.tasks
  end

  def test_define_task
    t = @tm.define_task(Rake::Task, :t)
    assert_equal "t", t.name
    assert_equal @tm, t.application
  end

  def test_index
    e = assert_raises RuntimeError do
      @tm["bad"]
    end

    assert_equal "Don't know how to build task 'bad' (See the list of available tasks with `rake --tasks`)", e.message
  end

  def test_undefined_task_with_custom_application
    Rake.application.init("myrake", nil)

    e = assert_raises RuntimeError do
      @tm["bad"]
    end

    assert_equal "Don't know how to build task 'bad' (See the list of available tasks with `myrake --tasks`)", e.message
  end

  def test_name_lookup
    t = @tm.define_task(Rake::Task, :t)
    assert_equal t, @tm[:t]
  end

  def test_namespace_task_create
    @tm.in_namespace("x") do
      t = @tm.define_task(Rake::Task, :t)
      assert_equal "x:t", t.name
    end
    assert_equal ["x:t"], @tm.tasks.map(&:name)
  end

  def test_define_namespaced_task
    t = @tm.define_task(Rake::Task, "n:a:m:e:t")
    assert_equal Rake::Scope.make("e", "m", "a", "n"), t.scope
    assert_equal "n:a:m:e:t", t.name
    assert_equal @tm, t.application
  end

  def test_define_namespace_in_namespace
    t = nil
    @tm.in_namespace("n") do
      t = @tm.define_task(Rake::Task, "a:m:e:t")
    end
    assert_equal Rake::Scope.make("e", "m", "a", "n"), t.scope
    assert_equal "n:a:m:e:t", t.name
    assert_equal @tm, t.application
  end

  def test_anonymous_namespace
    anon_ns = @tm.in_namespace(nil) do
      t = @tm.define_task(Rake::Task, :t)
      assert_equal "_anon_1:t", t.name
    end
    task = anon_ns[:t]
    assert_equal "_anon_1:t", task.name
  end

  def test_create_filetask_in_namespace
    @tm.in_namespace("x") do
      t = @tm.define_task(Rake::FileTask, "fn")
      assert_equal "fn", t.name
    end

    assert_equal ["fn"], @tm.tasks.map(&:name)
  end

  def test_namespace_yields_same_namespace_as_returned
    yielded_namespace = nil
    returned_namespace = @tm.in_namespace("x") do |ns|
      yielded_namespace = ns
    end
    assert_equal returned_namespace, yielded_namespace
  end

  def test_name_lookup_with_implicit_file_tasks
    FileUtils.touch "README.rdoc"

    t = @tm["README.rdoc"]

    assert_equal "README.rdoc", t.name
    assert Rake::FileTask === t
  end

  def test_name_lookup_with_nonexistent_task
    assert_raises(RuntimeError) {
      @tm["DOES NOT EXIST"]
    }
  end

  def test_name_lookup_in_multiple_scopes
    aa = nil
    bb = nil
    xx = @tm.define_task(Rake::Task, :xx)
    top_z = @tm.define_task(Rake::Task, :z)
    @tm.in_namespace("a") do
      aa = @tm.define_task(Rake::Task, :aa)
      mid_z = @tm.define_task(Rake::Task, :z)
      ns_d = @tm.define_task(Rake::Task, "n:t")
      @tm.in_namespace("b") do
        bb = @tm.define_task(Rake::Task, :bb)
        bot_z = @tm.define_task(Rake::Task, :z)

        assert_equal Rake::Scope.make("b", "a"), @tm.current_scope

        assert_equal bb, @tm["a:b:bb"]
        assert_equal aa, @tm["a:aa"]
        assert_equal xx, @tm["xx"]
        assert_equal bot_z, @tm["z"]
        assert_equal mid_z, @tm["^z"]
        assert_equal top_z, @tm["^^z"]
        assert_equal top_z, @tm["^^^z"] # Over the top
        assert_equal top_z, @tm["rake:z"]
      end

      assert_equal Rake::Scope.make("a"), @tm.current_scope

      assert_equal bb, @tm["a:b:bb"]
      assert_equal aa, @tm["a:aa"]
      assert_equal xx, @tm["xx"]
      assert_equal bb, @tm["b:bb"]
      assert_equal aa, @tm["aa"]
      assert_equal mid_z, @tm["z"]
      assert_equal top_z, @tm["^z"]
      assert_equal top_z, @tm["^^z"] # Over the top
      assert_equal top_z, @tm["rake:z"]
      assert_equal ns_d, @tm["n:t"]
      assert_equal ns_d, @tm["a:n:t"]
    end

    assert_equal Rake::Scope.make, @tm.current_scope

    assert_equal Rake::Scope.make, xx.scope
    assert_equal Rake::Scope.make("a"), aa.scope
    assert_equal Rake::Scope.make("b", "a"), bb.scope
  end

  def test_lookup_with_explicit_scopes
    t1, t2, t3, s = (0...4).map { nil }
    t1 = @tm.define_task(Rake::Task, :t)
    @tm.in_namespace("a") do
      t2 = @tm.define_task(Rake::Task, :t)
      s =  @tm.define_task(Rake::Task, :s)
      @tm.in_namespace("b") do
        t3 = @tm.define_task(Rake::Task, :t)
      end
    end
    assert_equal t1, @tm[:t, Rake::Scope.make]
    assert_equal t2, @tm[:t, Rake::Scope.make("a")]
    assert_equal t3, @tm[:t, Rake::Scope.make("b", "a")]
    assert_equal s,  @tm[:s, Rake::Scope.make("b", "a")]
    assert_equal s,  @tm[:s, Rake::Scope.make("a")]
  end

  def test_correctly_scoped_prerequisites_are_invoked
    values = []
    @tm = Rake::Application.new
    @tm.define_task(Rake::Task, :z) do values << "top z" end
    @tm.in_namespace("a") do
      @tm.define_task(Rake::Task, :z) do values << "next z" end
      @tm.define_task(Rake::Task, x: :z)
    end

    @tm["a:x"].invoke
    assert_equal ["next z"], values
  end

  def test_lazy_definition  
    t1, t2, t3 = nil, nil, nil
    lazy_definition_call_count = 0
    @tm.in_namespace("a1") do
      @tm.register_lazy_definition do
        t1 = @tm.define_task(Rake::Task, :t1)
        lazy_definition_call_count += 1
        @tm.in_namespace("a2") do
          t2 = @tm.define_task(Rake::Task, :t2)
        end
      end
    end
    @tm.in_namespace("b") do
      t3 = @tm.define_task(Rake::Task, :t3)
    end
    # task t3 is not lazy. It can be found
    assert_equal t3, @tm[:t3, Rake::Scope.make("b")]
    # lazy definition is not called until we look for task in namespace a
    assert_equal lazy_definition_call_count, 0

    # task t2 can be found
    found_task_t2 = @tm[:t2, Rake::Scope.make("a1:a2")]
    assert_equal t2, found_task_t2
    # lazy definition is expected to be called
    assert_equal lazy_definition_call_count, 1

    # task t1 can also be found
    found_task_t1 = @tm[:t1, Rake::Scope.make("a1")]
    assert_equal t1, found_task_t1
    # lazy definition is called at most once
    assert_equal lazy_definition_call_count, 1
  end

  def test_execute_all_lazy_definitions
    lazy_definition_call_count = 0
    @tm.in_namespace("a") do
      @tm.register_lazy_definition do
        lazy_definition_call_count += 1
      end
    end
    assert_equal lazy_definition_call_count, 0
    @tm.execute_all_lazy_definitions
    assert_equal lazy_definition_call_count, 1
    @tm.execute_all_lazy_definitions
    assert_equal lazy_definition_call_count, 1
  end

end
