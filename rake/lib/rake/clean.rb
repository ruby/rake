#!/usr/bin/env ruby

require 'rake'

CLEAN = Rake::FileList.new
CLEAN.add("**/*~", "**/*.bak", "**/core")

desc "Remove any temporary products."
task :clean do
  CLEAN.each { |fn| rm_r fn rescue nil }
end

CLOBBER = Rake::FileList.new

desc "Remove any generated file."
task :clobber => [:clean] do
  CLOBBER.each { |fn| rm_r fn rescue nil }
end
