
unless RUBY_PLATFORM =~ %r!cygwin!
  raise NotImplementedError, "cygwin-only module"
end

require 'fileutils'
require 'thread'

module Quix
  module Cygwin
    module_function

    def run_batchfile(file, *args)
      dos_pwd_env {
        sh("cmd", "/c", dos_path(file), *args)
      }
    end
    
    def normalize_path(path)
      path.sub(%r!/+\Z!, "")
    end
    
    def unix2dos(string)
      string.gsub(%r![^\r]\n!) { "#{$1}\r\n" }
    end
    
    def dos2unix(string)
      string.gsub("\r\n", "\n")
    end

    def dos_path(unix_path)
      `cygpath -w "#{normalize_path(unix_path)}"`.chomp
    end
  
    def unix_path(dos_path)
      escaped_path = dos_path.sub(%r!\\+\Z!, "").gsub("\\", "\\\\\\\\")
      `cygpath "#{escaped_path}"`.chomp
    end
    
    def dos_pwd_env
      Thread.exclusive {
        orig = ENV["PWD"]
        ENV["PWD"] = dos_path(Dir.pwd)
        begin
          yield
        ensure
          ENV["PWD"] = orig
        end
      }
    end
    
    def avoid_dll(file)
      temp_file = file + ".avoiding-link"
      FileUtils.mv(file, temp_file)
      begin
        yield
      ensure
        FileUtils.mv(temp_file, file)
      end
    end
  end
end
