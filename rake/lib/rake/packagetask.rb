#!/usr/bin/env ruby

module Rake

  class PackageTask
    attr_accessor :name, :version, :package_dir
    attr_reader :package_files

    def initialize(name, version)
      @name = name
      @version = version
      @package_files = Rake::FileList.new
      @package_dir = 'pkg'
    end

    def define
      desc "Build the package"
      task :package

      desc "Force a rebuild of the package files"
      task :repackage => [:clobber_package, :package]
      
      desc "Remove package products" 
      task :clobber_package do
	rm_r package_dir rescue nil
      end

      task :clobber => [:clobber_package]
      
      task :package => ["#{package_dir}/#{tgz_file}"]
      file "#{package_dir}/#{tgz_file}" => [package_dir_path] do
	chdir(package_dir) do
	  sh %{tar zcvf #{tgz_file} #{package_name}}
	end
      end

      task :package => ["#{package_dir}/#{zip_file}"]
      file "#{package_dir}/#{zip_file}" => [package_dir_path] do
	chdir(package_dir) do
	  sh %{zip -r #{zip_file} #{package_name}}
	end
      end

      file package_dir_path => @package_files do
	mkdir_p package_dir rescue nil
	@package_files.each do |fn|
	  f = File.join(package_dir_path, fn)
	  fdir = File.dirname(f)
	  mkdir_p(fdir) if !File.exist?(fdir)
	  if File.directory?(fn)
	    mkdir_p(f)
	  else
	    ln(fn, f)
	  end
	end
      end

    end

    private

    def package_name
      "#{@name}-#{@version}"
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

    
