#!/usr/bin/env ruby

require 'fileutils'
require 'rake/clean'
require 'rake/help'

# = Build rules for a Ruby Application

# == Classes

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
#    @web_publisher = CompositePublisher.new
#    @pkg_publisher = CompositePublisher.new
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
    
  end

end

