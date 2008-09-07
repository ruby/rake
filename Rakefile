$LOAD_PATH.unshift "contrib/quix/lib"

require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'quix/subpackager'

$VERBOSE = nil
require 'rdoc/rdoc'
$VERBOSE = true

require 'fileutils'
include FileUtils

gemspec = eval(File.read("comp_tree.gemspec"))
package_name = gemspec.name 
package_name_in_ruby = "CompTree"

# I would prefer "doc", but "html" is hard-coded for rubyforgepublisher
doc_dir = "html"

######################################################################
# clean

task :clean => [:clobber, :clean_doc] do
end

task :clean_doc do
  rm_rf(doc_dir)
end

######################################################################
# test

task :test do
  require 'test/all'
end

######################################################################
# package

task :package => :clean

Rake::GemPackageTask.new(gemspec) { |t|
  t.need_tar = true
}

######################################################################
# doc

task :doc => :clean_doc do 
  files = %w(README) + %w(driver error node task_node).map { |name|
    "lib/comp_tree/#{name}.rb"
  }

  options = [
    "-o", doc_dir,
    "--title", "comp_tree: #{gemspec.summary}",
    "--main", "README"
  ]

  RDoc::RDoc.new.document(files + options)
end

######################################################################
# repackage files from contrib/

task :generate_rb do
  packages = {
    :comp_tree => {
      :name_in_ruby => "CompTree",
      :lib_dir => "./lib",
      :subpackages => {
        :quix => {
          :name_in_ruby => "Quix",
          :sources => [
            "diagnostic",
            "kernel",
            "builtin/kernel/tap",
          ],
          :lib_dir => "./contrib/quix/lib",
          :ignore_root_rb => true,
        },
      },
    },
  }
  Quix::Subpackager.run(packages)
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

task :pull_contrib => [ :init_contrib, :run_pull_contrib, :generate_rb ]


######################################################################
# publisher

task :publish => :doc do
  Rake::RubyForgePublisher.new('comptree', 'quix').upload
end

######################################################################
# release

task :release => [:package, :publish]
