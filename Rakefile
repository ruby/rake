# Rakefile for rake        -*- ruby -*-

# Copyright 2003, 2004, 2005 by Jim Weirich (jim@weirichhouse.org)
# All rights reserved.

# This file may be distributed under an MIT style license.  See
# MIT-LICENSE for details.

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/test_*.rb']
end

begin
  require 'rdoc/task'

  RDoc::Task.new :rdoc => 'docs', :clobber_rdoc => 'clobber_docs' do |doc|
    doc.main   = 'README.rdoc'
    doc.title  = 'Rake -- Ruby Make'
    doc.rdoc_files = Rake::FileList.new %w[lib MIT-LICENSE doc/**/*.rdoc *.rdoc]
    doc.rdoc_dir = 'html'
  end
rescue LoadError
  warn 'run `rake newb` to install rdoc'
end
