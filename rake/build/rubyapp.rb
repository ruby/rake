#!/usr/bin/env ruby

require 'rake/clean'
require 'rake/help'

# = Build rules for a Ruby Application

# == Classes

# Configuration information about an upload host system.
# * name   :: Name of host system.
# * webdir :: Base directory for the web information for the
#             application.  The application name (APP) is appended to
#             this directory before using.
# * pkgdir :: Directory on the host system where packages can be
#             placed. 
HostInfo = Struct.new(:name, :webdir, :pkgdir)

# Publisher that uses SSH to move the files onto the web for publishing.
class SshPublisher
  attr_reader :host

  # Create a publisher using the give host information.
  def initialize(host_info)
    @host = host_info
  end

  # Upload the web material to the publish host.
  def upload_web(app, localdir='html')
    appdir = "#{@host.webdir}/#{app}"
    Sys.run %{ssh #{@host.name} rm -rf #{appdir}} rescue nil
    Sys.run %{ssh #{@host.name} mkdir -p #{appdir}}
    Sys.run %{scp -rq html/* #{@host.name}:#{appdir}}
  end
  
  # Upload the package files to the publish host.
  def upload_package(app, *files)
    Sys.run %{ssh #{@host.name} mkdir -p #{@host.pkgdir}/#{app}}
    files.each do |fn|
      if File.exist?("pkg/#{fn}")
	Sys.run %{scp -q pkg/#{fn} #{@host.name}:#{@host.pkgdir}/#{app}/#{fn}}
      end
    end
  end
end

######################################################################
# A publisher object that does nothing.  This is occasionally useful
# for testing.
class NullPublisher
  def upload_web(app, localdir=nil)
    puts "No publisher defined"
  end
  def upload_package(app, *files)
    puts "No publisher defined"
  end
end

######################################################################
class AppBuilder
  attr_reader :name
  attr_reader :package_files, :rdoc_files
  attr_accessor :rdoc_dir
  attr_reader :clean_files, :clobber_files
  attr_accessor :revision
  attr_accessor :publisher

  def initialize(app_name)
    @name = app_name
    @package_files = Rake::FileMatcher.new
    @rdoc_files    = Rake::FileMatcher.new
    @clobber_files = CLOBBER
    @clean_files   = CLEAN
    @revision = '0.0.0'
    @publisher = NullPublisher.new
    @rdoc_dir = 'html'
  end

  def revision_command(cmd)
    begin
      str = `#{cmd}`
      unless md = /(\d+\.\d+\.\d+)/.match(str)
	fail "No revision in (#{str})"
      end
      @revision = md[1]
    rescue Exception => ex
      puts "Unable to get revision: #{ex.message}"
    end
  end

  def package_name
    "#{name}-#{revision}"
  end

  def package_dir
    "pkg/#{package_name}"
  end

  def zip_file
    "#{package_name}.zip"
  end

  def tgz_file
    "#{package_name}.tgz"
  end

  def rdoc_target
    File.join(@rdoc_dir, "index.html")
  end

  def runtests(dir='.')
    Sys.quiet {
      Sys.ruby %{-Ilib -e 'Dir["#{dir}/test*.rb"].each { |fn| require fn }'}
    }
  end
  
  def create_package_directory(files)
    Sys.delete_all 'pkg' rescue nil
    Sys.makedirs(package_dir)
    files.each do |fn|
      f = File.join(package_dir, fn)
      fdir = File.dirname(f)
      Sys.makedirs(fdir) if !File.exist?(fdir)
      if File.directory?(fn)
	Sys.makedirs(f)
      else
	Sys.link fn, f
      end
    end
  end
    
  def create_tasks
    desc "Default Task"
    task :default => [:test]
    
    desc "Print the Application Revision"
    task :rev do
      puts revision
    end

    desc "Run all tests, both unit and acceptance"
    task :alltests => [		# Run the unit and acceptance tests (default)
      :test, :acceptance
    ]
    
    desc "Run unit tests"
    task :test do			# Run the Unit Tests
      runtests('test')
    end
    
    desc "Run acceptance tests"
    task :acceptance do	# Run acceptance tests
      runtests('acceptance')
    end
    
    # == Package Creation
    
    task :repackage => [:clean_package, :package]
    
    desc "Remove package products" 
    task :clean_package do
      Sys.delete_all "pkg"
    end
    
    desc "Build the distribution package" 
    task :package => [		# Create a distribution package
      "pkg/#{tgz_file}",
      "pkg/#{zip_file}",
    ]
    
    file "pkg/#{tgz_file}" => [package_dir] do
      Sys.indir("pkg") do
	Sys.run %{tar zcvf #{tgz_file} #{package_name}}
      end
    end
    
    file "pkg/#{zip_file}" => [package_dir] do
      Sys.indir("pkg") do
	Sys.run %{zip -r #{zip_file} #{package_name}}
      end
    end
    
    file package_dir do
      create_package_directory(package_files)
    end
    
    # == Publishing

    task :reweb => [:clear_web, :web]
    task :clear_web do
      Sys.delete_all "html"
    end
    
    desc "Build the web page"
    task :web => [		# Create all the files for a web installation 
      "Rakefile", :rdoc
    ]

    directory @rdoc_dir
    task :rdoc => [rdoc_target]
    file rdoc_target => @rdoc_files.to_a + ["Rakefile"] do
      Sys.delete_all @rdoc_dir
      Sys.run %{rdoc -o #{@rdoc_dir} --line-numbers --main README -T kilmer #{@rdoc_files}}
    end
    
    
    desc "Publish the web and package files"
    task :publish => [		# Publish the Application
      :publish_web, :publish_package
    ]
    
    desc "Publish the web documentation"
    task :publish_web => [:web] do
      @publisher.upload_web(@name)
    end
    
    desc "Publish the package files"
    task :publish_package => [:package] do
      @publisher.upload_package(@name, tgz_file, zip_file)
    end
    
    blurb_file = "#{@name}.blurb"
    if File.exist?(blurb_file)
      blurb_target = File.join("html", blurb_file)
      file blurb_target do
	Sys.copy blurb_file, blurb_target
      end
      task :web => [blurb_target]
    end

    # == Installation
    
    desc "Install the application"
    task :install do		# Install the application
      Sys.ruby "install.rb"
    end
  end

end

