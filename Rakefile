# Rakefile for rake        -*- ruby -*-

# Copyright 2003, 2004, 2005 by Jim Weirich (jim@weirichhouse.org)
# All rights reserved.

# This file may be distributed under an MIT style license.  See
# MIT-LICENSE for details.

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

begin
  old_verbose, $VERBOSE = $VERBOSE, nil
  require "bundler/gem_tasks"
rescue LoadError
ensure
  $VERBOSE = old_verbose
end

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.verbose = true
  t.test_files = FileList["test/**/test_*.rb"]
end

require "rdoc/task"
RDoc::Task.new do |doc|
  doc.main   = "README.rdoc"
  doc.title  = "Rake -- Ruby Make"
  doc.rdoc_files = FileList.new %w[lib MIT-LICENSE doc/**/*.rdoc *.rdoc]
  doc.rdoc_dir = "_site" # for github pages
end

namespace :rdoc do
  task :fix_links do
    %w[_site/index.html _site/README_rdoc.html].each do |path|
      fixed = File.read(path).gsub(%r{href="(doc/[^"]+?)\.rdoc"}, 'href="\1_rdoc.html"')
      File.write(path, fixed)
    end
  end
end

task rdoc: ["rdoc:fix_links"]

task default: :test
