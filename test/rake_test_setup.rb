# Common setup for all test files.

begin
  require 'rubygems'
  gem 'flexmock'
rescue LoadError
  # got no gems
end

require 'thread'
require 'flexmock/test_unit'

if RUBY_VERSION >= "1.9.0"
  class Test::Unit::TestCase
#    def passed?
#      true
#    end
  end
end

module TestMethods
  def assert_exception(ex, msg=nil, &block)
    assert_raise(ex, msg, &block)
  end
end

class SerializedArray
  def initialize
    @mutex = Mutex.new
    @array = Array.new
  end

  Array.public_instance_methods.each do |method_name|
    unless method_name =~ %r!\A__! or method_name =~ %r!\A(object_)?id\Z!
      # TODO: jettison 1.8.6; use define_method with |&block|
      eval %{
        def #{method_name}(*args, &block)
          @mutex.synchronize {
            @array.send('#{method_name}', *args, &block)
          }
        end
      }
    end
  end
end
