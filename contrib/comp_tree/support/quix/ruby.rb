
require 'rbconfig'

module Quix
  module Ruby
    EXECUTABLE = lambda {
      name = File.join(
        Config::CONFIG["bindir"],
        Config::CONFIG["RUBY_INSTALL_NAME"]
      )

      if Config::CONFIG["host"] =~ %r!(mswin|cygwin|mingw)! and
          File.basename(name) !~ %r!\.(exe|com|bat|cmd)\Z!i
        name + Config::CONFIG["EXEEXT"]
      else
        name
      end
    }.call

    class << self
      def run(*args)
        system(EXECUTABLE, *args)
      end

      def run_or_raise(*args)
        cmd = [EXECUTABLE, *args]
        unless system(*cmd)
          msg = (
            "failed to launch ruby: " +
            "system(*#{cmd.inspect}) failed with status #{$?.exitstatus}"
          )
          raise msg
        end
      end

      def with_warnings(value = true)
        previous = $VERBOSE
        $VERBOSE = value
        begin
          yield
        ensure
          $VERBOSE = previous
        end
      end
      
      def no_warnings(&block)
        with_warnings(false, &block)
      end
    end
  end
end
