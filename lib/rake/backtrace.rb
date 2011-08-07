module Rake
  module Backtrace
    SUPPRESSED_PATHS =
      RbConfig::CONFIG.values_at(*RbConfig::CONFIG.
                                 keys.grep(/(prefix|libdir)/)) + [
        File.join(File.dirname(__FILE__), ".."),
      ].map { |f| Regexp.quote(File.expand_path(f)) }

    SUPPRESS_PATTERN = %r!(\A#{SUPPRESSED_PATHS.join('|')}|bin/rake:\d+)!

    def self.collapse(backtrace)
      pattern = Rake.application.options.suppress_backtrace_pattern ||
                SUPPRESS_PATTERN
      backtrace.reject { |elem| elem =~ pattern }
    end
  end
end
