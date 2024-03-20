# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeDsl < Rake::TestCase # :nodoc:

  def setup
    super
    Rake::Task.clear
  end

  def test_namespace_command
    namespace "n" do
      task "t"
    end
    refute_nil Rake::Task["n:t"]
  end

  def test_namespace_command_with_bad_name
    ex = assert_raises(ArgumentError) do
      namespace 1 do end
    end
    assert_match(/string/i, ex.message)
    assert_match(/symbol/i, ex.message)
  end

  def test_namespace_command_with_a_string_like_object
    name = Object.new
    def name.to_str
      "bob"
    end
    namespace name do
      task "t"
    end
    refute_nil Rake::Task["bob:t"]
  end

  def test_no_commands_constant
    assert ! defined?(Commands), "should not define Commands"
  end

  def test_lazy
    call_count_t1 = 0
    call_count_t3 = 0
    namespace "a" do
      lazy do
        task "t1"
        call_count_t1 += 1
      end
    end
    namespace "b" do
      task "t2"
      namespace "c" do
        lazy do
          namespace "d" do
            lazy do
              task "t3"
              call_count_t3 += 1
            end
          end
        end
      end
    end
    refute_nil Rake::Task["b:t2"]
    assert_equal 0, call_count_t1
    assert_equal 0, call_count_t3
    refute_nil Rake::Task["a:t1"]
    assert_equal 1, call_count_t1
    assert_equal 0, call_count_t3
    refute_nil Rake::Task["b:c:d:t3"]
    assert_equal 1, call_count_t1
    assert_equal 1, call_count_t3
  end

end
