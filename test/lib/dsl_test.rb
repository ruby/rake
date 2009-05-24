#!/usr/bin/env ruby

begin
  require 'rubygems'
rescue LoadError
  # got no gems
end

require 'test/unit'
require 'flexmock/test_unit'
require 'rake'
require 'test/rake_test_setup'

class DslTest < Test::Unit::TestCase
  def test_namespace_command
    namespace "n" do
      task "t"
    end
    assert_not_nil Rake::Task["n:t"]
  end

  def test_namespace_command_with_bad_name
    ex = assert_raise(ArgumentError) do
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
    assert_not_nil Rake::Task["bob:t"]
  end
end
