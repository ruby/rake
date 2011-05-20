begin
  require 'rubygems'
rescue LoadError
end
require 'test/unit'
require 'flexmock/test_unit'

require 'rake'

class Test::Unit::TestCase
  include Rake::DSL

  def ignore_deprecations
    Rake.application.options.ignore_deprecate = true
    yield
  ensure
    Rake.application.options.ignore_deprecate = false
  end
end
