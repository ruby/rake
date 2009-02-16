
require 'rbconfig'

module Config
  CONFIG["ruby_executable"] =
    CONFIG["RUBY_EXECUTABLE"] =
      File.join(CONFIG["bindir"], CONFIG["RUBY_INSTALL_NAME"])
end
