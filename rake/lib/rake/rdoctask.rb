#!/usr/bin/env ruby

require 'rake'
require 'rake/tasklib'

module Rake

  # Create a documentation task that will generate the RDoc files for
  # a project.
  #
  # The PackageTask will create the following targets:
  #
  # [<b><em>name</em></b>]
  #   Main task for this RDOC task.  
  #
  # [<b>:clobber_<em>name</em></b>]
  #   Delete all the package files.  This target is automatically
  #   added to the main clobber target.
  #
  # [<b>:re<em>name</em></b>]
  #   Rebuild the package files from scratch, even if they are not out
  #   of date.
  #
  # Simple Example:
  #
  #   RDocTask.new do |rd|
  #     rd.main = "README.rdoc"
  #     rd.package_files.include("lib/**/*.rb")
  #   end
  #
  class RDocTask < TaskLib
    # Name of the main, top level task.  (default is :rdoc)
    attr_accessor :name

    # Name of directory to receive the html output files. (default is "html")
    attr_accessor :rdoc_dir

    # Title of RDoc documentation. (default is none)
    attr_accessor :title

    # Name of file to be used as the main, top level file of the
    # RDoc. (default is none)
    attr_accessor :main

    # Name of template to be used by rdoc. (default is 'html')
    attr_accessor :template

    # List of files to be included in the rdoc generation. (default is [])
    attr_accessor :rdoc_files

    # List of options to be passed rdoc.  (default is [])
    attr_accessor :options

    # Create an RDoc task named <em>name</em>.  
    def initialize(name=:rdoc)
      @name = name
      @rdoc_files = Rake::FileList.new
      @rdoc_dir = 'html'
      @main = nil
      @title = nil
      @template = 'html'
      @options = []
      yield self if block_given?
      define
    end
    
    # Create the tasks defined by this task lib.
    def define
      if name.to_s != "rdoc"
	desc "Build the RDOC HTML Files"
      end

      desc "Build the #{name} HTML Files"
      task name
      
      desc "Force a rebuild of the RDOC files"
      task paste("re", name) => [paste("clobber_", name), name]
      
      desc "Remove rdoc products" 
      task paste("clobber_", name) do
	rm_r rdoc_dir rescue nil
      end

      task :clobber => [paste("clobber_", name)]
      
      directory @rdoc_dir
      task name => [rdoc_target]
      file rdoc_target => @rdoc_files + ["Rakefile"] do
	rm_r @rdoc_dir rescue nil
	opts = @options.join(' ')
	opts << " --main '#{main}'" if main
	opts << " --title '#{title}'" if title
	opts << " -T '#{template}'" if template
	sh %{rdoc -o #{@rdoc_dir} #{opts} #{@rdoc_files}}
      end
      self
    end
    
    private

    def rdoc_target
      "#{rdoc_dir}/index.html"
    end

  end
end

    
