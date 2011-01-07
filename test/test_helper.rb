begin
  require 'rubygems'
rescue LoadError
end
require 'test/unit'
require 'flexmock/test_unit'

require 'rake'

class Test::Unit::TestCase
  include Rake::DSL
end
