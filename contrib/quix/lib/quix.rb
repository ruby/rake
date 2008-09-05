#
# Convience only -- include most everything
#

root = File.dirname(__FILE__)
pkgname = File.basename(__FILE__).sub(%r!\.rb\Z!, "")
 
Dir["#{root}/#{pkgname}/**/*.rb"].map { |file|
  # change to relative paths
  file.sub(%r!\A#{root}/!, "").sub(%r!\.rb\Z!, "")
}.reject { |file|
  (file =~ %r!cygwin! and RUBY_PLATFORM !~ %r!cygwin!) or
  file =~ %r!builtin!
}.each { |file|
  require file
}

require 'quix/builtin/kernel/tap'

%w(Config Enumerable FileUtils String).each { |name|
  Kernel.const_get(name).module_eval {
    include Quix.const_get(name)
  }
}

Config.extend(Quix::Config)

class Object
  include Quix::Kernel
end

include Quix
