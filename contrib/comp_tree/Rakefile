$LOAD_PATH.unshift "contrib/quix/lib"

require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

$VERBOSE = nil
require 'rdoc/rdoc'
$VERBOSE = true

require 'fileutils'
include FileUtils

GEMSPEC = eval(File.read("comp_tree.gemspec"))
DOC_DIR = "html"

######################################################################
# clean

task :clean => [:clobber, :clean_doc] do
end

task :clean_doc do
  rm_rf(DOC_DIR)
end

######################################################################
# test

task :test do
  require 'test/all'
end

######################################################################
# package

task :package => :clean

Rake::GemPackageTask.new(GEMSPEC) { |t|
  t.need_tar = true
}

######################################################################
# doc

task :doc => :clean_doc do 
  files = %w(README) + %w(driver error node task_node).map { |name|
    "lib/comp_tree/#{name}.rb"
  }

  options = [
    "-o", DOC_DIR,
    "--title", "comp_tree: #{GEMSPEC.summary}",
    "--main", "README"
  ]

  RDoc::RDoc.new.document(files + options)
end

######################################################################
# git

def git(*args)
  cmd = ["git"] + args
  sh(*cmd)
end

task :init_contrib do
  unless `git remote`.split.include? "quix"
    git(*%w!remote add -f quix git@github.com:quix/quix.git!)
  end
end

task :add_contrib_first_time => :init_contrib do
  git(*%w!merge --squash -s ours --no-commit quix/master!)
  git(*%w!read-tree --prefix=contrib/quix -u quix/master!)
  git("commit", "-m", "add quix utils")
end

task :run_pull_contrib do
  git(*%w!pull --no-commit -s subtree quix master!)
end

task :pull_contrib => [ :init_contrib, :run_pull_contrib ]

######################################################################
# publisher

task :publish => :doc do
  Rake::RubyForgePublisher.new('comptree', 'quix').upload
end

######################################################################
# release

task :prerelease => :clean do
  rm_rf(DOC_DIR)
  rm_rf("pkg")
  unless `git status` =~ %r!nothing to commit \(working directory clean\)!
    raise "Directory not clean"
  end
  unless `ping -c2 github.com` =~ %r!0% packet loss!i
    raise "No ping for github.com"
  end
end

def rubyforge(command, file)
  sh("rubyforge",
     command,
     GEMSPEC.rubyforge_project,
     GEMSPEC.rubyforge_project,
     GEMSPEC.version.to_s,
     file)
end

task :finish_release do
  gem, tgz = %w(gem tgz).map { |ext|
    "pkg/#{GEMSPEC.name}-#{GEMSPEC.version}.#{ext}"
  }
  gem_md5, tgz_md5 = [gem, tgz].map { |file|
    "#{file}.md5".tap { |md5|
      sh("md5sum #{file} > #{md5}")
    }
  }

  rubyforge("add_release", gem)
  rubyforge("add_file", gem_md5)
  rubyforge("add_file", tgz)
  rubyforge("add_file", tgz_md5)

  git("tag", "comp_tree-" + GEMSPEC.version.to_s)
  git(*%w(push --tags origin master))
end

task :release =>
  [
   :prerelease,
   :package,
   :publish,
   :finish_release,
  ]
