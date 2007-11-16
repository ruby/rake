
module Ruby19
  PROG = '/Users/jim/local/ruby19/bin/ruby'
  GEM_HOME = '/Users/jim/local/ruby19/lib/ruby/gems/1.9'

  def run_tests(files)
    sh "#{PROG} -Ilib lib/rake/rake_test_loader.rb #{files}"
  end

  extend self
end

namespace "ruby19" do
  namespace "test" do

    desc "Check the file paths"
    task :check do
      raise "Ruby 1.9 executable not found" unless File.exist?(Ruby19::PROG)
      raise "Ruby 1.9 Gem Home not found"   unless File.exist?(Ruby19::GEM_HOME)
    end

    task :env19 => :check do
      ENV['GEM_HOME'] = Ruby19::GEM_HOME
    end

    desc "Describe the Ruby 1.9 version used for testing"
    task :version => [:env19] do
      sh "#{Ruby19::PROG} --version", :verbose => false
      sh "#{Ruby19::PROG} -rubygems -e 'puts \"Gem Path = \#{Gem.path}\"'", :verbose => false
    end

    desc "Run the unit tests in Ruby 1.9"
    task :units => [:env19] do
      test_files = FileList['test/test_*.rb']
      Ruby19.run_tests(test_files)
    end

    desc "Run the unit tests in Ruby 1.9"
    task :functionals => [:env19] do
      test_files = FileList['test/functional.rb']
      Ruby19.run_tests(test_files)
    end

    desc "Run the unit tests in Ruby 1.9"
    task :functionals => [:env19] do
      test_files = FileList['test/functional.rb', 'test/test_*.rb']
      Ruby19.run_tests(test_files)
    end
  end
end
