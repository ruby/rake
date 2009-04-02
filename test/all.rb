here = File.dirname(__FILE__)
$LOAD_PATH.unshift here + "../support"

require 'quix/ruby'

Dir["#{here}/test_*.rb"].each { |file|
  Quix::Ruby.run_or_raise("-w", file, *ARGV)
}
