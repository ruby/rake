#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'flexmock'
require 'rake'

class TestNameSpace < Test::Unit::TestCase
  def test_namespace_creation
    FlexMock.use("TaskManager") do |mgr|
      ns = Rake::NameSpace.new(mgr, [])
      assert_not_nil ns
    end
  end

  def test_namespace_lookup
    FlexMock.use("TaskManager") do |mgr|
      mgr.should_receive(:lookup).with(:t, ["a"]).
	and_return(nil).once
      ns = Rake::NameSpace.new(mgr, ["a"])
      ns[:t]
    end
  end
end
