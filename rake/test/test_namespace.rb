#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'flexmock'
require 'rake'

class TestNameSpace < Test::Unit::TestCase
  include FlexMock::TestCase

  def test_namespace_creation
    mgr = flexmock("TaskManager")
    ns = Rake::NameSpace.new(mgr, [])
    assert_not_nil ns
  end

  def test_namespace_lookup
    mgr = flexmock("TaskManager")
    mgr.should_receive(:lookup).with(:t, ["a"]).
      and_return(nil).once
    ns = Rake::NameSpace.new(mgr, ["a"])
    ns[:t]
  end
end
