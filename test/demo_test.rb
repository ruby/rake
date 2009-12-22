require 'test/unit'

class DemoTest < Test::Unit::TestCase
  def test_demo
    assert_raises RuntimeError do
      raise "OUCH"
    end
  end
end
