module Rake
  module Backtrace
    SUPPRESSED_PATHS = [
      RbConfig::CONFIG["prefix"],
      File.join(File.dirname(__FILE__), ".."),
    ].map { |f| Regexp.quote(File.expand_path(f)) }

    SUPPRESS_PATTERN = %r!(\A#{SUPPRESSED_PATHS.join('|')}|bin/rake:\d+)!

    # Elide backtrace elements which match one of SUPPRESS_PATHS.
    def self.collapse(backtrace)
      backtrace.reject { |elem| elem =~ SUPPRESS_PATTERN }
    end
  end
end
