#!/usr/bin/env ruby

module Rake

  # Create a documentation task that will generate the RDoc files for
  # a project.
  #
  # The PackageTask will create the following targets:
  #
  # [<b><em>name</em></b>]
  #   Main task for this RDOC task.  
  #
  # [<b>:rdoc</b>]
  #   Create the RDoc HTML files.  If task is only recreated 
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
  #     rd.package_files.add("lib/**/*.rb")
  #   end
  #
  class RDocTask
    # Name of the main, top level task.  (default is :rdoc)
    attr_accessor :name

    # Name of directory to receive the html output files. (default is "html")
    attr_accessor :rdoc_dir

    # Name of file to be used as the main, top level file of the
    # RDoc. (default 'README')
    attr_accessor :main

    # Name of template to be used by rdoc. (default is 'html')
    attr_accessor :template

    # List of files to be included in the rdoc generation. (default is [])
    attr_reader :rdoc_files

    # List of options to be passed rdoc.  (default is [])
    attr_reader :options

    # Create an RDoc task named <em>name</em>.  
    def initialize(name=:rdoc)
      @name = name
      @rdoc_files = Rake::FileList.new
      @rdoc_dir = 'html'
      @main = 'README'
      @template = 'html'
      @options = []
      yield self if block_given?
      define
    end
    
    private

    def define
      if name.to_s != "rdoc"
	desc "Build the RDOC HTML Files"
	task :rdoc => [name]
      end

      desc "Build the #{name} HTML Files"
      task name
      
      desc "Force a rebuild of the RDOC files"
      task paste("re", name) => [paste("clean_", name), name]
      
      desc "Remove rdoc products" 
      task paste("clobber_", name) do
	rm_r rdoc_dir rescue nil
      end

      task :clobber => [paste("clobber_", name)]
      
      directory @rdoc_dir
      task name => [rdoc_target]
      file rdoc_target => @rdoc_files + ["Rakefile"] do
	rm_r @rdoc_dir rescue nil
	sh %{rdoc -o #{@rdoc_dir} #{@options} --main #{main} -T #{template} #{@rdoc_files}}
      end
      self
    end
    
    def rdoc_target
      "#{rdoc_dir}/index.html"
    end

    def paste(a,b)
      (a.to_s + b.to_s).intern
    end

  end
end

    
