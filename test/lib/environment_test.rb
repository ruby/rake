#!/usr/bin/env ruby

require 'test/test_helper'
require 'rake/environment'

class TestEnvironment < Test::Unit::TestCase
  def test_load_string
    Rake::Task.clear
    Rake::Environment.load_string("task :xyz")
    assert Rake::Task[:xyz], "should have a task named xyz"
  end

  def test_load_rakefile
    Rake::Task.clear
    Rake::Environment.load_rakefile("test/data/default/Rakefile")
    assert Rake::Task[:default], "Should have a default task"
  end
end
