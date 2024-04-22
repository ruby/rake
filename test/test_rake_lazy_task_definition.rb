# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeLazyTaskDefinition < Rake::TestCase # :nodoc:

  def setup
    super

    @tm = Rake::TestCase::TaskManager.new
    @tm.extend Rake::LazyTaskDefinition
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
