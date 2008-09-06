
require 'rbconfig'

module Quix
  module Config
    CONFIG = ::Config::CONFIG

    def ruby_executable
      File.join(CONFIG["bindir"], CONFIG["RUBY_INSTALL_NAME"])
    end
    
    def version_gt(version) ; version_compare( :>, version) ; end
    def version_lt(version) ; version_compare( :<, version) ; end
    def version_eq(version) ; version_compare(:==, version) ; end
    def version_ge(version) ; version_compare(:>=, version) ; end
    def version_le(version) ; version_compare(:<=, version) ; end
    def version_ne(version) ; version_compare(:"!=", version) ; end
    
    def version_compare(op, version)
      major, minor, teeny =
        version.split(".").map { |n| n.to_i }
      
      this_major, this_minor, this_teeny = 
        %w(MAJOR MINOR TEENY).map { |v| CONFIG[v].to_i }
      
      if this_major == major and this_minor == minor
        this_teeny.send(op, teeny)
      elsif this_major == major
        this_minor.send(op, minor)
      else
        this_major.send(op, major)
      end
    end
    
    extend self
  end
end
