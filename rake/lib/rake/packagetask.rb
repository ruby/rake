#!/usr/bin/env ruby

# Define a package task libarary to aid in the definition of
# redistributable package files.

require 'rake'
require 'rake/tasklib'

module Rake

  # Create a packaging task that will package the project into
  # distributable files (e.g zip archive or tar files).
  #
  # The PackageTask will create the following targets:
  #
  # [<b>:package</b>]
  #   Create all the requested package files.
  #
  # [<b>:clobber_package</b>]
  #   Delete all the package files.  This target is automatically
  #   added to the main clobber target.
  #
  # [<b>:repackage</b>]
  #   Rebuild the package files from scratch, even if they are not out
  #   of date.
  #
  # [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.tgz"</b>]
  #   Create a gzipped tar package (if <em>need_tar</em> is true).  
  #
  # [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.zip"</b>]
  #   Create a zip package archive (if <em>need_zip</em> is true).
  #
  # Example:
  #
  #   PackageTask.new("rake", "1.2.3") do |p|
  #     p.need_tar = true
  #     p.package_files.include("lib/**/*.rb")
  #   end
  #
  class PackageTask < TaskLib
    # Name of the package (from the GEM Spec).
    attr_accessor :name

    # Version of the package (e.g. '1.3.2').
    attr_accessor :version

    # Directory used to store the package files (default is 'pkg').
    attr_accessor :package_dir

    # True if a gzipped tar file should be produced (default is false).
    attr_accessor :need_tar

    # True if a zip file should be produced (default is false)
    attr_accessor :need_zip

    # List of files to be included in the package.
    attr_accessor :package_files

    # Create a Package Task with the given name and version. 
    def initialize(name=nil, version=nil)
      init(name, version)
      yield self if block_given?
      define unless name.nil?
    end

    # Initialization that bypasses the "yield self" and "define" step.
    def init(name, version)
      @name = name
      @version = version
      @package_files = Rake::FileList.new
      @package_dir = 'pkg'
      @need_tar = false
      @need_zip = false
    end

    # Create the tasks defined by this task library.
    def define
      fail "Version required (or :noversion)" if @version.nil?
      @version = nil if @version == :noversion

      desc "Build all the packages"
      task :package
      
      desc "Force a rebuild of the package files"
      task :repackage => [:clobber_package, :package]
      
      desc "Remove package products" 
      task :clobber_package do
	rm_r package_dir rescue nil
      end

      task :clobber => [:clobber_package]

      if need_tar
	task :package => ["#{package_dir}/#{tgz_file}"]
	file "#{package_dir}/#{tgz_file}" => [package_dir_path] + package_files do
	  chdir(package_dir) do
	    sh %{tar zcvf #{tgz_file} #{package_name}}
	  end
	end
      end

      if need_zip
	task :package => ["#{package_dir}/#{zip_file}"]
	file "#{package_dir}/#{zip_file}" => [package_dir_path] + package_files do
	  chdir(package_dir) do
	    sh %{zip -r #{zip_file} #{package_name}}
	  end
	end
      end

      directory package_dir

      file package_dir_path => @package_files do
	mkdir_p package_dir rescue nil
	@package_files.each do |fn|
	  f = File.join(package_dir_path, fn)
	  fdir = File.dirname(f)
	  mkdir_p(fdir) if !File.exist?(fdir)
	  if File.directory?(fn)
	    mkdir_p(f)
	  else
	    rm_f f
	    ln(fn, f)
	  end
	end
      end
      self
    end

    private

    def package_name
      @version ? "#{@name}-#{@version}" : @name
    end
      
    def package_dir_path
      "#{package_dir}/#{package_name}"
    end

    def tgz_file
      "#{package_name}.tgz"
    end

    def zip_file
      "#{package_name}.zip"
    end
  end

end

    
