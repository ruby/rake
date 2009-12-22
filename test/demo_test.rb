require 'test/unit'
require 'test/rake_test_setup'

class DemoTest < Test::Unit::TestCase
  include TestMethods

  def test_demo
    assert_exception RuntimeError do
      raise "OUCH"
    end
  end
end
