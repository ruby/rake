#!/usr/bin/env ruby

# Load the test files from the command line.

ARGV.each do |f| 
  next if f =~ /^-/

  if f =~ /\*/
    FileList[f].to_a.each { |f| load f }
  else
    load f
  end
end

