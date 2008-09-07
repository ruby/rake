
require 'rake/gempackagetask'

gemspec = eval(File.read("comp_tree.gemspec"))
package_name = gemspec.name 
package_name_in_ruby = "CompTree"

task :clean => :clobber

task :test do
  require 'test/all'
end

Rake::GemPackageTask.new(gemspec) {
}

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

require 'rake/contrib/rubyforgepublisher'

task :publish => :rdoc do
  Rake::RubyForgePublisher.new('comptree', 'quix').upload
end

######################################################################
# release

task :release => [:gem, :publish]
