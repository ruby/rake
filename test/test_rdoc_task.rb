#!/usr/bin/env ruby

require 'test/unit'
require 'rake/rdoctask'
require 'test/rake_test_setup'

class TestRDocTask < Test::Unit::TestCase
  include Rake
  include TestMethods
  
  def test_tasks_creation
    Rake::RDocTask.new
    assert Task[:rdoc]
    assert Task[:clobber_rdoc]
    assert Task[:rerdoc]
  end
  
  def test_tasks_creation_with_custom_name
    rd = Rake::RDocTask.new(:rdoc_dev)
    assert Task[:rdoc_dev]
    assert Task[:clobber_rdoc_dev]
    assert Task[:rerdoc_dev]
    assert_equal :rdoc_dev, rd.name
  end
end
