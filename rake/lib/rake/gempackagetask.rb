#!/usr/bin/env ruby

# Define a package task library to aid in the definition of GEM
# packages.

require 'rubygems'
require 'rake'
require 'rake/packagetask'

module Rake

  class GemPackageTask < PackageTask
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

    
