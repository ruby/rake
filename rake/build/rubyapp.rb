#!/usr/bin/env ruby

require 'fileutils'
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

class CompositePublisher
  def initialize
    @publishers = []
  end

  def add(pub)
    @publishers << pub
  end

  def upload
    @publishers.each { |p| p.upload }
  end
end

# Publish an entire directory to an existing remote directory using
# SSH.
class SshDirPublisher
  def initialize(host, remote_dir, local_dir)
    @host = host
    @remote_dir = remote_dir
    @local_dir = local_dir
  end

  def upload
    run %{scp -rq #{@local_dir}/* #{@host}:#{@remote_dir}}
  end
end

# Publish an entire directory to a fresh remote directory using SSH.
class SshFreshDirPublisher < SshDirPublisher
  def upload
    run %{ssh #{@host} rm -rf #{@remote_dir}} rescue nil
    run %{ssh #{@host} mkdir #{@remote_dir}}
    super
  end
end

# Publish a list of files to an existing remote directory.
class SshFilePublisher
  # Create a publisher using the give host information.
  def initialize(host, remote_dir, local_dir, *files)
    @host = host
    @remote_dir = remote_dir
    @local_dir = local_dir
    @files = files
  end

  # Upload the local directory to the remote directory.
  def upload
    @files.each do |fn|
      run %{scp -q #{@local_dir}/#{fn} #{@host}:#{@remote_dir}}
    end
  end
end

######################################################################
class AppBuilder
  attr_reader :name
  attr_reader :package_files, :rdoc_files
  attr_accessor :rdoc_dir
  attr_reader :clean_files, :clobber_files
  attr_accessor :revision
  attr_accessor :web_publisher
  attr_accessor :pkg_publisher

  def initialize(app_name)
    @name = app_name
    @package_files = Rake::FileList.new
    @rdoc_files    = Rake::FileList.new
    @clobber_files = CLOBBER
    @clean_files   = CLEAN
    @revision = '0.0.0'
    @web_publisher = CompositePublisher.new
    @pkg_publisher = CompositePublisher.new
    @rdoc_dir = 'html'
  end

  def revision_command(cmd)
    begin
      str = `#{cmd}`
      unless md = /(\d+\.\d+\.\d+[a-z]*)/.match(str)
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

  def create_package_directory(files)
    rm_r 'pkg' rescue nil
    mkdir_p package_dir
    files.each do |fn|
      f = File.join(package_dir, fn)
      fdir = File.dirname(f)
      mkdir_p(fdir) if !File.exist?(fdir)
      if File.directory?(fn)
	mkdir_p(f)
      else
	ln(fn, f)
      end
    end
  end
    
  def create_tasks
    desc "Default Task"
    
    desc "Print the Application Revision"
    task :rev do
      puts revision
    end

    desc "Run all tests, both unit and acceptance"
    task :alltests => [		# Run the unit and acceptance tests (default)
      :test, :acceptance
    ]
    
    desc "Run acceptance tests"
    task :acceptance do	# Run acceptance tests
      runtests('acceptance')
    end
    
    # == Publishing

    desc "Force a rebuild of the web documents"
    task :reweb => [:clear_web, :web]
    task :clear_web do
      rm_r "html" rescue nil
    end
    
    desc "Build the web page"
    task :web => [		# Create all the files for a web installation 
      "Rakefile", :rdoc
    ]

    directory @rdoc_dir
    task :rdoc => [rdoc_target]
    file rdoc_target => @rdoc_files.to_a + ["Rakefile"] do
      rm_r @rdoc_dir rescue nil
      run %{rdoc -o #{@rdoc_dir} --line-numbers --main README -T kilmer #{@rdoc_files}}
    end
    
    desc "Publish the web and package files"
    task :publish => [		# Publish the Application
      :publish_web, :publish_package
    ]
    
    desc "Publish the web documentation"
    task :publish_web => [:web] do
      @web_publisher.upload
    end
    
    desc "Publish the package files"
    task :publish_package => [:package] do
      @pkg_publisher.upload
    end
    
    # == Installation
    
    desc "Install the application"
    task :install do		# Install the application
      ruby "install.rb"
    end
  end

end

