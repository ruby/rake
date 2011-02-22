#!/usr/bin/env ruby

require 'test/unit'
require 'test/filecreation'
begin
  old_verbose = $VERBOSE
  $VERBOSE = nil
  require 'rake/contrib/sys'
ensure
  $VERBOSE = old_verbose
end

class TestSys < Test::Unit::TestCase
  include FileCreation

  def test_split_all
    assert_equal ['a'], Sys.split_all('a')
    assert_equal ['..'], Sys.split_all('..')
    assert_equal ['/'], Sys.split_all('/')
    assert_equal ['a', 'b'], Sys.split_all('a/b')
    assert_equal ['/', 'a', 'b'], Sys.split_all('/a/b')
    assert_equal ['..', 'a', 'b'], Sys.split_all('../a/b')
  end
end
