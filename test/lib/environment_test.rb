#!/usr/bin/env ruby

require 'test/test_helper'
require 'rake/environment'

class TestEnvironment < Test::Unit::TestCase
  def test_load_rakefile
    Rake::Task.clear
    Rake::Environment.load_rakefile("test/data/default/Rakefile")
    assert Rake::Task[:default], "Should have a default task"
  end

  def test_run
    Rake::Task.clear
    Rake::Environment.run do
      desc "demo comment"
      task :default
    end
    assert Rake::Task[:default], "Should have a default task"
  end

  def test_environment
    Rake::Task.clear
    Rake::DSL.environment do
      desc "demo comment"
      task :default
    end
    assert Rake::Task[:default], "Should have a default task"
  end
end
