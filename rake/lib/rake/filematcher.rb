#!/usr/bin/env ruby

require 'rake/filelist'

module Rake
  class FileMatcher
    include Enumerable
    
    def initialize
      @files = Rake::FileList.new
      @wildcards = Array.new
      @anti_patterns = Array.new
    end
    
    def <<(file)
      case file
      when Array
	file.each { |f| @files << f }
      else
	@files << file
      end
      self
    end
    
    def add_matching(pattern)
      @files.add_matching(pattern)
    end
    
    def match(*wildcards)
      fail "WARNING: Use 'glob' instead of 'match'"
    end
    
    def glob(*wildcards)
      wildcards.each { |wc| @wildcards << wc }
    end
    
    def no_match(*anti_patterns)
      anti_patterns.each do |anti_pattern|
	case anti_pattern
	when String
	  @anti_patterns << Regexp.new(Regexp.quote(anti_pattern))
	else
	  @anti_patterns << anti_pattern
	end
      end
    end
    
    def each(&block)
      @files.reject { |fn| reject?(fn) }.each(&block)
      @wildcards.each { |card|
	Dir[card].reject { |fn| reject?(fn) }.each(&block)
      }
    end
    
    alias files to_a
    
    def to_s
      files.join(' ')
    end
    
    def reject?(fn)
      @anti_patterns.each { |anti| return true if anti.match(fn) }
      false
    end
  end
  
end
