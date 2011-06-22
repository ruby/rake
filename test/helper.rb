require 'rubygems'
require 'minitest/unit'
require 'flexmock/test_unit_integration'
require 'minitest/autorun'
require 'rake'
require 'tmpdir'
require File.expand_path('../file_creation', __FILE__)
require File.expand_path('../in_environment', __FILE__)

class Rake::TestCase < MiniTest::Unit::TestCase
  include FlexMock::ArgumentTypes
  include FlexMock::MockContainer

  include InEnvironment
  include FileCreation

  include Rake::DSL

  class TaskManager
    include Rake::TaskManager
  end

  def setup
    ARGV.clear

    @orig_PWD = Dir.pwd
    @orig_RAKE_COLUMNS = ENV['RAKE_COLUMNS']
    @orig_RAKE_SYSTEM  = ENV['RAKE_SYSTEM']
    @orig_RAKEOPT      = ENV['RAKEOPT']
    ENV.delete 'RAKE_COLUMNS'
    ENV.delete 'RAKE_SYSTEM'
    ENV.delete 'RAKEOPT'

    tmpdir = Dir.chdir Dir.tmpdir do Dir.pwd end
    @tempdir = File.join tmpdir, "test_rake_#{$$}"

    FileUtils.mkdir_p @tempdir
  end

  def teardown
    flexmock_teardown

    Dir.chdir @orig_PWD
    FileUtils.rm_rf @tempdir

    if @orig_RAKE_COLUMNS then
      ENV['RAKE_COLUMNS'] = @orig_RAKE_COLUMNS
    else
      ENV.delete 'RAKE_COLUMNS'
    end

    if @orig_RAKE_SYSTEM then
      ENV['RAKE_SYSTEM'] = @orig_RAKE_SYSTEM
    else
      ENV.delete 'RAKE_SYSTEM'
    end

    if @orig_RAKEOPT then
      ENV['RAKEOPT'] = @orig_RAKEOPT
    else
      ENV.delete 'RAKEOPT'
    end
  end

  def ignore_deprecations
    Rake.application.options.ignore_deprecate = true
    yield
  ensure
    Rake.application.options.ignore_deprecate = false
  end

  def rake_system_dir
    @system_dir = File.join @tempdir, 'system'

    FileUtils.mkdir_p @system_dir

    open File.join(@system_dir, 'sys1.rake'), 'w' do |io|
      io << <<-SYS
task "sys1" do
  puts "SYS1"
end
      SYS
    end

    ENV['RAKE_SYSTEM'] = @system_dir

    Dir.chdir @tempdir
  end

  def rakefile contents
    open File.join(@tempdir, 'Rakefile'), 'w' do |io|
      io << contents
    end

    Dir.chdir @tempdir
  end

  def rakefile_default
    rakefile <<-DEFAULT
if ENV['TESTTOPSCOPE']
  puts "TOPSCOPE"
end

task :default do
  puts "DEFAULT"
end

task :other => [:default] do
  puts "OTHER"
end

task :task_scope do
  if ENV['TESTTASKSCOPE']
    puts "TASKSCOPE"
  end
end
    DEFAULT
  end

  def rakefile_unittest
    rakefile '# Empty Rakefile for Unit Test'

    subdir = File.join @tempdir, 'subdir'
    FileUtils.mkdir_p subdir

    readme = File.join subdir, 'README'
    FileUtils.touch readme
  end

end

# workarounds for 1.8
$" << 'test/helper.rb'
Test::Unit.run = true if Test::Unit.respond_to? :run=

