#!/usr/bin/env ruby

require 'rake'
require 'rake/filematcher'

CLEAN = Rake::FileList.new
CLEAN.add_matching("**/*~", "**/*.bak", "**/core")

task :clean do
  CLEAN.each { |fn| Sys.delete_all fn rescue nil }
end

CLOBBER = Rake::FileList.new

task :clobber => [:clean] do
  CLOBBER.each { |fn| Sys.delete_all fn rescue nil }
end
