$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'quix/config'

#
# Run in separate exec to check for missing dependencies.
#
Dir["#{File.dirname(__FILE__)}/test_*.rb"].each { |test|
  unless system(Quix::Config.ruby_executable, test)
    raise "test failed: #{test}"
  end
}
