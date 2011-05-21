require 'rubygems'
require 'minitest/unit'
require 'flexmock/test_unit_integration'
require 'minitest/autorun'
require 'rake'

class Rake::TestCase < MiniTest::Unit::TestCase
  include FlexMock::ArgumentTypes
  include FlexMock::MockContainer

  include Rake::DSL

  def teardown
    flexmock_teardown
    super
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

