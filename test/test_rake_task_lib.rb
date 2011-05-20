#!/usr/bin/env ruby

require 'test/unit'
require 'rake/tasklib'


class TestRakeTaskLib < Test::Unit::TestCase
  def test_paste
    tl = Rake::TaskLib.new
    assert_equal :ab, tl.paste(:a, :b)
  end
end
