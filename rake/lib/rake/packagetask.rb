#!/usr/bin/env ruby

# Define a package task libarary to aid in the definition of
# redistributable package files.

require 'rake'
require 'rake/tasklib'

begin
  require 'rubygems'
rescue Exception
  puts "Unable to find RubyGEMS"
  fail "The Package Task Lib requires RubyGEMS"
end

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
  # [<b>:gem</b>]
  #   Create the Ruby GEM file.
  #
  # [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.tgz"</b>]
  #   Create a gzipped tar package.  
  #
  # [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.zip"</b>]
  #   Create a zip package archive.
  #
  # [<b>"<em>package_dir</em>/<em>name</em>-<em>version</em>.gem"</b>]
  #   Create a Ruby GEM package.
  #
  # Simple Example:
  #
  #   PackageTask.new("rake", "1.2.3") do |p|
  #     p.need_tar = true
  #     p.package_files.include("lib/**/*.rb")
  #   end
  #
  # Example using a Ruby GEM spec:
  #
  #   spec = Gem::Specification.new do |s|
  #     s.platform = Gem::Platform::RUBY
  #     s.summary = "Ruby based make-like utility."
  #     s.name = 'rake'
  #     s.version = PKG_VERSION
  #     s.requirements << 'none'
  #     s.require_path = 'lib'
  #     s.autorequire = 'rake'
  #     s.files = PKG_FILES
  #     s.description = <<EOF
  #   Rake is a Make-like program implemented in Ruby. Tasks
  #   and dependencies are specified in standard Ruby syntax. 
  #   EOF
  #   end
  #   
  #   Rake::PackageTask.new(spec) do |pkg|
  #     pkg.gem_spec = spec
  #     pkg.need_zip = true
  #     pkg.need_tar = true
  #   end
  #
  class SimplePackageTask < TaskLib
    # Name of the package (from the GEM Spec).
    attr_reader :name

    # Version of the package (e.g. '1.3.2', from the GEM Spec).
    attr_accessor :version

    # Directory used to store the package files (default is 'pkg').
    attr_accessor :package_dir

    # Ruby GEM spec containing the metadata for this package.  If a
    # GEM spec is provided, then name, version and package_files are
    # automatically determined and don't need to be explicitly
    # provided.  A GEM file will be produced if and only if a GEM spec
    # is supplied.
    attr_accessor :gem_spec

    # True if a gzipped tar file should be produced (default is false).
    attr_accessor :need_tar

    # True if a zip file should be produced (default is false)
    attr_accessor :need_zip

    # List of files to be included in the package.
    attr_reader :package_files

    # Create a Package Task with the given name and version.  Omit
    # name and version if a gemspec is supplied.
    def initialize(name=nil, version=nil)
      init(name, version)
      yield self if block_given?
      define if block_given?
    end

    def init(name, version)
      @name = name
      @version = version
      @package_files = Rake::FileList.new
      @package_dir = 'pkg'
      @need_tar = false
      @need_zip = false
    end

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

  class GemPackageTask < SimplePackageTask
    def initialize(gem)
      init(gem)
      yield self if block_given?
      define if block_given?
    end

    def init(gem)
      super(gem.name, gem.version)
      @gem_spec = gem
      @package_files += gem_spec.files if gem_spec.files
    end

    def define
      super
      task :package => [:gem]
      task :gem => ["#{package_dir}/#{gem_file}"]
      file "#{package_dir}/#{gem_file}" => [package_dir] + @gem_spec.files do
	when_writing("Creating GEM") {
	  Gem::Builder.new(gem_spec).build
	  verbose(false) {
	    mv gem_file, "#{package_dir}/#{gem_file}"
	  }
	}
      end
    end
    
    private
    
    def gem_file
      "#{package_name}.gem"
    end
    
  end
end

    
