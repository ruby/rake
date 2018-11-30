# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakePathMapPartial < Rake::TestCase # :nodoc:
  def test_pathmap_partial
    @path = "1/2/file".dup
    def @path.call(n)
      pathmap_partial(n)
    end
    assert_equal("1", @path.call(1))
    assert_equal("1/2", @path.call(2))
    assert_equal("1/2", @path.call(3))
    assert_equal(".", @path.call(0))
    assert_equal("2", @path.call(-1))
    assert_equal("1/2", @path.call(-2))
    assert_equal("1/2", @path.call(-3))
  end
end
