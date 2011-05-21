require 'rubygems'
require 'test/unit'
require 'flexmock/test_unit'

require 'test/capture_stdout'
require 'test/file_creation'

require 'rake'

class Rake::TestCase < Test::Unit::TestCase
  include Rake::DSL

  def ignore_deprecations
    Rake.application.options.ignore_deprecate = true
    yield
  ensure
    Rake.application.options.ignore_deprecate = false
  end

  def assert_exception(ex, msg="", &block)
    assert_raise(ex, msg, &block)
  end
end
