#!/usr/bin/env ruby

require 'rake'

module Rake
  def self.gather_comment_lines(fn=nil)
    fn ||= $rakefile
    lines = []
    open(fn) do |rfile|
      while line = rfile.gets
	if md = /^(task|file)\s+(:\w+|"\w+").*[^#]#[^#](.*)$/.match(line)
	  target_name, comment = md[2], md[3]
	  target_name.sub!(/^[:"]/, '')
	  target_name.sub!(/"$/, '')
	  lines << [target_name, comment]
	end
      end
    end
    lines
  end
end

task :help do			# Display Rake Targets
  puts
  puts "Rakefile Targets"
  lines = Rake.gather_comment_lines
  width = lines.collect { |ln| ln[0].size }.max
  lines.sort.each { |name, comment|
    printf "  %-#{width}s  -- %s\n", name, comment
  }
end
