require 'rubygems'
require 'minitest/unit'
require 'flexmock/test_unit_integration'
require 'minitest/autorun'
require 'rake'
require File.expand_path('../file_creation', __FILE__)
require File.expand_path('../in_environment', __FILE__)

class Rake::TestCase < MiniTest::Unit::TestCase
  include FlexMock::ArgumentTypes
  include FlexMock::MockContainer

  include InEnvironment
  include FileCreation

  include Rake::DSL

  class TaskManager
    include Rake::TaskManager
  end

  def setup
    @orig_PWD = Dir.pwd
  end

  def teardown
    flexmock_teardown

    Dir.chdir @orig_PWD
  end

  def ignore_deprecations
    Rake.application.options.ignore_deprecate = true
    yield
  ensure
    Rake.application.options.ignore_deprecate = false
  end

end

# workarounds for 1.8
$" << 'test/helper.rb'
Test::Unit.run = true if Test::Unit.respond_to? :run=

class ThreadSafeArray
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
