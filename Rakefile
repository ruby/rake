$LOAD_PATH.unshift "contrib/quix/lib"

require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'find'

$VERBOSE = nil
require 'rdoc/rdoc'
$VERBOSE = true

require 'fileutils'
include FileUtils

GEMSPEC = eval(File.read("comp_tree.gemspec"))
DOC_DIR = "html"
COVERAGE_DIR = "coverage"

######################################################################
# clean

task :clean => [:clobber, :clean_doc] do
  rm_rf COVERAGE_DIR
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
# coverage

task :cov do
  rm_rf(COVERAGE_DIR)
  system("rcov", "-o", COVERAGE_DIR, *Dir["test/test_*.rb"])
end

######################################################################
# debug

def comment_src_dst(on)
  on ? ["", "#"] : ["#", ""]
end

def comment_regions(on, contents, start)
  src, dst = comment_src_dst(on)
  contents.gsub(%r!^(\s+)#{src}#{start}.*?^\1#{src}(\}|end)!m) { |chunk|
    indent = $1
    chunk.gsub(%r!^#{indent}#{src}!, "#{indent}#{dst}")
  }
end

def comment_lines(on, contents, start)
  src, dst = comment_src_dst(on)
  contents.gsub(%r!^(\s*)#{src}#{start}!) { 
    $1 + dst + start
  }
end

def debug_info(debug)
  on = !debug
  Find.find("lib", "test") { |path|
    if path =~ %r!\.rb\Z!
      replace_file(path) { |contents|
        res1 = comment_regions(on, contents, "def trace_compute")
        res2 = comment_regions(on, res1, "debug")
        res3 = comment_lines(on, res2, "trace")
      }
    end
  }
end

task :debug_on do
  debug_info(true)
end

task :debug_off do
  debug_info(false)
end

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

######################################################################
# util

def replace_file(file)
  old_contents = File.read(file)
  yield(old_contents).tap { |new_contents|
    if old_contents != new_contents
      File.open(file, "wb") { |output|
        output.print(new_contents)
      }
    end
  }
end

