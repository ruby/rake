#!/usr/bin/env ruby

module Rake
  class FileList < Array
    def initialize(pattern=nil)
      add_matching(pattern) if pattern
    end

    def add_matching(pattern)
      Dir[pattern].each { |fn| self << fn } if pattern
    end

    def to_s
      self.join(' ')
    end
  end
end
