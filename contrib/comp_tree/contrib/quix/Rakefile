$LOAD_PATH.unshift "./lib"

require 'quix/simple_installer'
require 'quix/config'

task :test do
  load './test/all.rb'
end

task :install do
  Quix::SimpleInstaller.new.install
end

task :uninstall do
  Quix::SimpleInstaller.new.uninstall
end
