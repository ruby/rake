#!/usr/bin/env ruby

module Rake

  class PackageTask
    attr_accessor :name, :version, :package_dir
    attr_accessor :gem_spec
    attr_accessor :need_tar, :need_zip
    attr_reader :package_files

    def initialize(name=nil, version=nil)
      @name = name
      @version = version
      @package_files = Rake::FileList.new
      @package_dir = 'pkg'
      @need_tar = false
      @need_zip = false
      @gem_spec = nil
      yield self if block_given?
      define
    end

    def define
      copy_from_gem if gem_spec

      desc "Build the package"
      task :package
      
      desc "Create a RubyGem for #{name}"
      task :gem

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

      if gem_spec
	task :package => [:gem]
	task :gem => ["#{package_dir}/#{gem_file}"]
	file "#{package_dir}/#{gem_file}" => [package_dir] + package_files do
	  when_writing("Creating GEM") {
	    Gem::Builder.new(gem_spec).build
	    verbose(false) {
	      mv gem_file, "#{package_dir}/#{gem_file}"
	    }
	  }
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

    def copy_from_gem
      @name = gem_spec.name
      @version = gem_spec.version
      @package_files += gem_spec.files if gem_spec.files
    end

    def package_name
      "#{@name}-#{@version}"
    end
      
    def package_dir_path
      "#{package_dir}/#{package_name}"
    end

    def gem_file
      "#{package_name}.gem"
    end

    def tgz_file
      "#{package_name}.tgz"
    end

    def zip_file
      "#{package_name}.zip"
    end
  end
end

    
