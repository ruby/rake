
require 'rbconfig'

Dir["#{File.dirname(__FILE__)}/test_*.rb"].map { |file|
  File.expand_path(file)
}.each { |file|
  # spawn separate processes to avoid EAGAIN signals on fork
  ruby = File.join(
    Config::CONFIG["bindir"],
    Config::CONFIG["RUBY_INSTALL_NAME"])
  system(ruby, file)
}
