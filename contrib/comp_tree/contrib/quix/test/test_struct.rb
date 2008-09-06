$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'quix/lazy_struct'
require 'quix/hash_struct'

class TestLazyStruct < Test::Unit::TestCase
  def common(s)
    s.f = 33
    assert_equal(33, s.f)

    n = 0
    s.attribute(:f) {
      n += 1
      44
    }
    
    3.times {
      assert_equal(44, s.f)
    }
    assert_equal(1, n)
  end

  def test_1
    common(Quix::LazyStruct.new)
  end

  def test_2
    s = OpenStruct.new
    class << s
      include Quix::LazyStruct::Mixin
    end
    common(s)
  end

  def test_3
    s = Quix::HashStruct.new
    class << s
      include Quix::LazyStruct::Mixin
    end
    common(s)
    s[:g] = 55
    assert_equal(
      { :f => 33, :g => 55 },
      s.keys.inject(Hash.new) { |acc, e| acc.merge(e => s[e]) })
  end
end

