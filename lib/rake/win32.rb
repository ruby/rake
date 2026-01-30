# frozen_string_literal: true
require "rbconfig"

module Rake
  # Win 32 interface methods for Rake. Windows specific functionality
  # will be placed here to collect that knowledge in one spot.
  module Win32 # :nodoc: all

    class << self
      # True if running on a windows system.
      def windows?
        RbConfig::CONFIG["host_os"] =~ %r!(msdos|mswin|djgpp|mingw|[Ww]indows)!
      end
    end

  end
end
