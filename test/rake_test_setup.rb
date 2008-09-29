# Common setup for all test files.

begin
  require 'rubygems'
  gem 'flexmock'
rescue LoadError
  # got no gems
end

require 'flexmock/test_unit'

if RUBY_VERSION >= "1.9.0"
  class Test::Unit::TestCase
#    def passed?
#      true
#    end
  end
end

module TestMethods
  if RUBY_VERSION >= "1.9.0"
    def assert_no_match(expected_pattern, actual, msg=nil)
      refute_match(expected_pattern, actual, msg)
    end
    def assert_not_equal(expected, actual, msg=nil)
      refute_equal(expected, actual, msg)
    end
    def assert_nothing_raised
      yield
    end
    def assert_not_nil(actual, msg=nil)
      refute_nil(actual, msg)
    end
    def assert_exception(ex, msg=nil, &block)
      assert_raises(ex, msg, &block)
    end
  elsif RUBY_VERSION >= "1.8.0"
    def assert_exception(ex, msg=nil, &block)
      assert_raise(ex, msg, &block)
    end
  end
end
