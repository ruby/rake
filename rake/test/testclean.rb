#!/usr/bin/env ruby

require 'test/unit'
require 'rake/clean'

class TestClean < Test::Unit::TestCase
  def test_clean
    assert_not_nil Task['clean']
    assert_not_nil Task['clobber']
    assert Task['clobber'].prerequisites.include?("clean"),
      "Clobber should require clean"
  end
end
