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

require 'rubygems/package_task'

require 'rake/clean'
require 'rake/testtask'

gem 'rdoc'
require 'rdoc/task'

CLEAN.include('**/*.o', '*.dot', '**/*.rbc')
CLOBBER.include('doc/example/main')
CLOBBER.include('TAGS')

# Prevent OS X from including extended attribute junk in the tar output
ENV['COPY_EXTENDED_ATTRIBUTES_DISABLE'] = 'true'

def announce(msg='')
  STDERR.puts msg
end

# Determine the current version of the software

if `ruby -Ilib ./bin/rake --version` =~ /rake, version ([0-9a-z.]+)$/
  CURRENT_VERSION = $1
else
  CURRENT_VERSION = "0.0.0"
end

$package_version = CURRENT_VERSION

SRC_RB = FileList['lib/**/*.rb']

# The default task is run if rake is given no explicit arguments.

desc "Default Task"
task :default => :test

# Test Tasks ---------------------------------------------------------

Rake::TestTask.new do |t|
  files = FileList['test/helper.rb', 'test/test_*.rb']
  t.loader = :rake
  t.test_files = files
  t.libs << "."
  t.warning = true
end

# CVS Tasks ----------------------------------------------------------

# Create a task to build the RDOC documentation tree.

BASE_RDOC_OPTIONS = [
  '--line-numbers', '--show-hash',
  '--main', 'README.rdoc',
  '--title', 'Rake -- Ruby Make'
]

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'html'
  rdoc.title    = "Rake -- Ruby Make"
  rdoc.options = BASE_RDOC_OPTIONS.dup

  rdoc.rdoc_files.include('README.rdoc', 'MIT-LICENSE', 'TODO', 'CHANGES')
  rdoc.rdoc_files.include('lib/**/*.rb', 'doc/**/*.rdoc')
  rdoc.rdoc_files.exclude(/\bcontrib\b/)
end

# ====================================================================
# Create a task that will package the Rake software into distributable
# tar, zip and gem files.

PKG_FILES = FileList[
  '.gemtest',
  'install.rb',
  'CHANGES',
  'MIT-LICENSE',
  'README.rdoc',
  'Rakefile',
  'TODO',
  'bin/rake',
  'lib/**/*.rb',
  'test/**/*.rb',
  'doc/**/*'
]
PKG_FILES.exclude('doc/example/*.o')
PKG_FILES.exclude('TAGS')
PKG_FILES.exclude(%r{doc/example/main$})

SPEC = Gem::Specification.new do |s|
  s.name = 'rake'
  s.version = $package_version
  s.summary = "Ruby based make-like utility."
  s.license = "MIT"
  s.description = <<-EOF.delete "\n"
Rake is a Make-like program implemented in Ruby. Tasks and dependencies are
specified in standard Ruby syntax.
  EOF

  s.required_ruby_version = '>= 1.9'
  s.required_rubygems_version = '>= 1.3.2'
  s.add_development_dependency 'minitest', '~> 4'

  s.files = PKG_FILES.to_a

  s.executables = ["rake"]

  s.extra_rdoc_files = FileList[
    'README.rdoc',
    'MIT-LICENSE',
    'TODO',
    'CHANGES',
    'doc/**/*.rdoc'
  ]

  s.rdoc_options = BASE_RDOC_OPTIONS

  s.author = "Jim Weirich"
  s.email = "jim.weirich@gmail.com"
  s.homepage = "http://github.com/jimweirich/rake"
end

Gem::PackageTask.new(SPEC) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

file "rake.gemspec" => ["Rakefile", "lib/rake.rb"] do |t|
  require 'yaml'
  open(t.name, "w") { |f| f.puts SPEC.to_yaml }
end

desc "Create a stand-alone gemspec"
task :gemspec => "rake.gemspec"

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

