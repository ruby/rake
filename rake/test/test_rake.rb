#!/usr/bin/env ruby

require 'test/unit'
require 'rake'

class TestRake < Test::Unit::TestCase
  def test_each_dir_parent
    assert_equal ['a'], alldirs('a')
    assert_equal ['a/b', 'a'], alldirs('a/b')
    assert_equal ['/a/b', '/a', '/'], alldirs('/a/b')
    assert_equal ['c:/a/b', 'c:/a', 'c:'], alldirs('c:/a/b')
    assert_equal ['c:a/b', 'c:a'], alldirs('c:a/b')
  end

  def alldirs(fn)
    result = []
    Rake.each_dir_parent(fn) { |d| result << d }
    result
  end
    
end
