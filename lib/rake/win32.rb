# Win 32 interface methods for Rake.
module Rake
  module Win32
    
    # Error indicating a problem in locating the home directory on a
    # Win32 system.
    class Win32HomeError < RuntimeError
    end
    
    class << self
      # True if running on a windows system.
      def windows?
        Config::CONFIG['host_os'] =~ /mswin/
      end

      # Run a command line on windows.
      def rake_system(*cmd)
        if cmd.size == 1
          system("call #{cmd}")
        else
          system(*cmd)
        end
      end
      
      # The standard directory containing system wide rake files on Win
      # 32 systems.
      def win32_system_dir #:nodoc:
        win32_shared_path = ENV['APPDATA']
        if win32_shared_path.nil? && ENV['HOMEDRIVE'] && ENV['HOMEPATH']
          win32_shared_path = ENV['HOMEDRIVE'] + ENV['HOMEPATH']
        end
        win32_shared_path ||= ENV['USERPROFILE']
        raise Win32HomeError, "Unable to determine home path environment variable." if
          win32_shared_path.nil? or win32_shared_path.empty?
        normalize(File.join(win32_shared_path, 'Rake'))
      end
      
      # Normalize a win32 path so that the slashes are all forward slashes.
      def normalize(path)
        path.gsub(/\\/, '/')
      end
      
    end
  end
end
