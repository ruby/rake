#
# Convience only -- include most everything
#

require 'quix/builtin/kernel/tap.rb'
require 'quix/config.rb'
require 'quix/diagnostic.rb'
require 'quix/enumerable.rb'
require 'quix/fileutils.rb'
require 'quix/hash_struct.rb'
require 'quix/kernel.rb'
require 'quix/lazy_struct.rb'
require 'quix/pathname.rb'
require 'quix/simple_installer.rb'
require 'quix/string.rb'
require 'quix/subpackager.rb'
require 'quix/thread_local.rb'
require 'quix/vars.rb'

%w[
  Config
  Enumerable
  FileUtils 
  String 
  Pathname
].each { |name|
  Kernel.const_get(name).module_eval {
    include Quix.const_get(name)
  }
}

Pathname.extend(Quix::Pathname::Meta)
Config.extend(Quix::Config)

class Object
  include Quix::Kernel
end

include Quix
