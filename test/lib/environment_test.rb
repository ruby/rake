#!/usr/bin/env ruby

require 'test/test_helper'
require 'rake/environment'

class TestEnvironment < Test::Unit::TestCase
  def test_load_string
    Rake::Environment.load_string("task :xyz")
    assert Rake::Task[:xyz], "should have a task named xyz"
  end
end
