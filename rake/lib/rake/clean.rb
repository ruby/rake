#!/usr/bin/env ruby

require 'rake'
require 'rake/filematcher'

CLEAN = Rake::FileMatcher.new
CLEAN.glob("**/*~", "**/*.bak", "**/core")

task :clean do
  CLEAN.each { |fn| Sys.delete_all fn rescue nil }
end

CLOBBER = Rake::FileMatcher.new

task :clobber => [:clean] do
  CLOBBER.each { |fn| Sys.delete_all fn rescue nil }
end
