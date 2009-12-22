require 'test/unit'
require 'test/rake_test_setup'

class DemoTest < Test::Unit::TestCase
  include TestMethods

  def test_demo
    ex = nil
    e = StandardError.new
    ex.instance_of?(Module) ? e.kind_of?(ex) : ex == e.class
  end
end
