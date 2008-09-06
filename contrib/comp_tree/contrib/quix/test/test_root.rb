$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'quix'
require 'test/unit'

class TestRoot < Test::Unit::TestCase
  def test_1
    assert_equal(class << self ; self ; end, singleton_class)
    assert_equal("moo", "moo".tap { |t| t*2 })
    assert_equal("moomoo", "moo".let { |t| t*2 })
    assert_equal("zzz", " zzz     ".trim)
    assert_nothing_raised {
      ThreadLocal.new
      LazyStruct.new
      HashStruct.new
      Config.ruby_executable
    }
  end
end
