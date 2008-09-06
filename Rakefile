$LOAD_PATH.unshift "./contrib/quix/lib"

require 'quix/simple_installer'
require 'quix/subpackager'

require 'rake/packagetask'
require 'rake/rdoctask'

require 'fileutils'
include FileUtils

package_name = "comp_tree"
package_name_in_ruby = "CompTree"

version = File.open("VERSION") { |f| f.read }.gsub(%r!\s!, "")

package_files =
  %w(README VERSION Rakefile test/Rakefile) +
  Dir["**/*.rb"] +
  Dir["doc/**/*"]

Rake::PackageTask.new(package_name, version) { |t|
  t.need_tar_bz2 = true
  t.package_files = package_files
}

Rake::RDocTask.new { |t|
  readme = "README"
  t.main = readme
  t.rdoc_dir = "doc"
  t.rdoc_files = [
    readme,
    "lib/comp_tree/driver.rb",
  ]
  p t.rdoc_files 
}

task :install do
  Quix::SimpleInstaller.new.install
end

task :uninstall do
  Quix::SimpleInstaller.new.uninstall
end

task :distclean do
  rm_rf(["pkg", ".config", "doc"])
end

task :test do
  require 'test/all'
end

begin
  require 'rake/gempackagetask'
  gem_spec = Gem::Specification.new { |t|
    t.author = "James M. Lawrence"
    t.email = "quixoticsycophant@gmail.com"
    t.platform = Gem::Platform::RUBY
    t.summary = "Parallel computation tree."
    t.name = package_name
    t.version = version
    t.requirements << 'none'
    t.require_path = 'lib'
    t.files = package_files
    t.description = t.summary
    t.has_rdoc = true
  }
  Rake::GemPackageTask.new(gem_spec) { |t|
    t.need_tar_bz2 = true
  }
rescue LoadError
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

######################################################################
# toplevel

task :pull_contrib => [ :init_contrib, :run_pull_contrib, :generate_rb ]
