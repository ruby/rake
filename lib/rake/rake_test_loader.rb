#!/usr/bin/env ruby
require 'rake'

# Load the test files from the command line.

ARGV.each do |f| 
  next if f =~ /^-/

  if f =~ /\*/
    FileList[f].to_a.each { |fn| load fn }
  else
    load f
  end
end

