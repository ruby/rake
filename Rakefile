# Rakefile for rake        -*- ruby -*-

# Copyright 2003, 2004, 2005 by Jim Weirich (jim@weirichhouse.org)
# All rights reserved.

# This file may be distributed under an MIT style license.  See
# MIT-LICENSE for details.

require 'rbconfig'

system_rake = File.join RbConfig::CONFIG['rubylibdir'], 'rake.rb'

# Use our rake, not the installed rake from system
if $".include? system_rake or $".grep(/rake\/name_space\.rb$/).empty? then
  exec Gem.ruby, '-Ilib', 'bin/rake', *ARGV
end

require 'hoe'

hoe = Hoe.spec 'rake' do
  developer 'Eric Hodel', 'drbrain@segment7.net'
  developer 'Jim Weirich', ''

  require_ruby_version     '>= 1.9'
  require_rubygems_version '>= 1.3.2'

  dependency 'minitest', '~> 4.0', :developer

  license "MIT"

  self.readme_file  = 'README.rdoc'
  self.history_file = 'History.rdoc'

  self.extra_rdoc_files.concat FileList[
    'MIT-LICENSE',
    'TODO',
    'CHANGES',
    'doc/**/*.rdoc'
  ]

  self.clean_globs += [
    '**/*.o',
    '**/*.rbc',
    '*.dot',
    'TAGS',
    'doc/example/main',
  ]
end

# Use custom rdoc task due to existence of doc directory

Rake::Task['docs'].clear
Rake::Task['clobber_docs'].clear

require 'rdoc/task'

RDoc::Task.new :rdoc => 'docs', :clobber_rdoc => 'clobber_docs' do |doc|
  doc.main   = hoe.readme_file
  doc.title  = 'Rake -- Ruby Make'

  rdoc_files = Rake::FileList.new %w[lib History.rdoc MIT-LICENSE doc]
  rdoc_files.add hoe.extra_rdoc_files

  doc.rdoc_files = rdoc_files

  doc.rdoc_dir = 'html'
end

SRC_RB = FileList['lib/**/*.rb']

# Misc tasks =========================================================

def count_lines(filename)
  lines = 0
  codelines = 0
  open(filename) { |f|
    f.each do |line|
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
  }
  [lines, codelines]
end

def show_line(msg, lines, loc)
  printf "%6s %6s   %s\n", lines.to_s, loc.to_s, msg
end

desc "Count lines in the main rake file"
task :lines do
  total_lines = 0
  total_code = 0
  show_line("File Name", "LINES", "LOC")
  SRC_RB.each do |fn|
    lines, codelines = count_lines(fn)
    show_line(fn, lines, codelines)
    total_lines += lines
    total_code  += codelines
  end
  show_line("TOTAL", total_lines, total_code)
end

# Support Tasks ------------------------------------------------------

RUBY_FILES = FileList['**/*.rb'].exclude('pkg')

desc "Look for TODO and FIXME tags in the code"
task :todo do
  RUBY_FILES.egrep(/#.*(FIXME|TODO|TBD)/)
end

desc "List all ruby files"
task :rubyfiles do
  puts RUBY_FILES
  puts FileList['bin/*'].exclude('bin/*.rb')
end
task :rf => :rubyfiles

