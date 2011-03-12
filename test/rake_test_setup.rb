# Common setup for all test files.

begin
  require 'rubygems'
  gem 'flexmock'
rescue LoadError
  # got no gems
end

require 'flexmock/test_unit'
require 'test/file_creation'
require 'test/capture_stdout'
require 'test/test_helper'

module TestMethods
  # Shim method for compatibility
  def assert_exception(ex, msg="", &block)
    assert_raise(ex, msg, &block)
  end
end
