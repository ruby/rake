module Rbx
  PROG = '/usr/local/bin/rbx'
  GEM_HOME = '/usr/local/lib/rubinius/gems/1.8'

  RELEASE_FILES = FileList['bin/rake', 'lib/rake.rb', 'lib/rake/**/*']
  RELEASE_FILES.exclude('lib/rake/lib', 'project.rake', 'lib/rake/plugins', 'lib/rake/contrib')

  SVN = "../thirdparty/ruby"

  def run_tests(files, opts='')
    sh "#{PROG} -Ilib lib/rake/rake_test_loader.rb #{opts} #{files}"
  end

  extend self
end

namespace "rbx" do
  desc "Ruby Release Files"
  task :release_files do
    puts Rbx::RELEASE_FILES
  end

  desc "Release Rake Files to Ruby 19 SVN working area"
  task :release => [:check_svn] do
    dirs = Rbx::RELEASE_FILES.select { |fn| File.directory?(fn) }
    dirs.each do |dir| mkdir_p "#{Rbx::SVN}/#{dir}" end
    Rbx::RELEASE_FILES.each do |fn|
      cp fn, "#{Rbx::SVN}/#{fn}" unless File.directory?(fn)
    end
  end

  desc "Remove Rake from the Ruby 19 SVN"
  task :unrelease => [:check_svn] do
    rm_r "#{Rbx::SVN}/bin/rake" rescue nil
    rm_r "#{Rbx::SVN}/lib/rake" rescue nil
    rm_r "#{Rbx::SVN}/lib/rake.rb" rescue nil
  end

  task :check_svn do
    fail "Cannot find Ruby 1.9 SVN directory: #{Rbx::SVN}" unless
      File.directory?(Rbx::SVN)
  end


  namespace "test" do

    desc "Check the file paths"
    task :check do
      raise "Ruby 1.9 executable not found" unless File.exist?(Rbx::PROG)
      raise "Ruby 1.9 Gem Home not found"   unless File.exist?(Rbx::GEM_HOME)
    end

    task :env19 => :check do
      ENV['GEM_HOME'] = Rbx::GEM_HOME
    end

    desc "Describe the Ruby 1.9 version used for testing"
    task :version => [:env19] do
      sh "#{Rbx::PROG} --version", :verbose => false
      sh "#{Rbx::PROG} -rubygems -e 'puts \"Gem Path = \#{Gem.path}\"'", :verbose => false
      sh "#{Rbx::PROG} -Ilib bin/rake --version"
    end

    desc "Run the unit tests in Ruby 1.9"
    task :units, :opts, :needs => [:env19] do |t, args|
      test_files = FileList['test/lib/*_test.rb']
      Rbx.run_tests(test_files, args.opts)
    end

    desc "Run the functional tests in Ruby 1.9"
    task :functionals, :opts, :needs => [:env19] do |t, args|
      test_files = FileList['test/functional/*_test.rb']
      Rbx.run_tests(test_files, args.opts)
    end

    desc "Run the all the tests in Ruby 1.9"
    task :all, :opts, :needs => [:env19] do |t, args|
      test_files = FileList['test/functional/*_test.rb', 'test/lib/*_test.rb']
      Rbx.run_tests(test_files, args.opts)
    end
  end
end
