require File.expand_path('../helper', __FILE__)

class TestRakeScope < Rake::TestCase
  include Rake

  def test_empty_scope
    scope = Scope.make
    assert_equal scope, Scope::EMPTY
    assert_equal scope.path, ""
  end

  def test_with_one_element
    scope = Scope.make(:one)
    assert_equal "one", scope.path
  end

  def test_with_two_elements
    scope = Scope.make(:inner, :outer)
    assert_equal "outer:inner", scope.path
  end

  def test_path_with_task_name
    scope = Scope.make(:inner, :outer)
    assert_equal "outer:inner:task", scope.path_with_task_name("task")
  end

  def test_path_with_task_name_on_empty_scope
    scope = Scope.make
    assert_equal "task", scope.path_with_task_name("task")
  end
end
