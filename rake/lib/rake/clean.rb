#!/usr/bin/env ruby

require 'rake'
require 'rake/filelist'

CLEAN = Rake::FileList.new
CLEAN.add("**/*~", "**/*.bak", "**/core")

task :clean do
  CLEAN.each { |fn| rm_r fn rescue nil }
end

CLOBBER = Rake::FileList.new

task :clobber => [:clean] do
  CLOBBER.each { |fn| rm_r fn rescue nil }
end
