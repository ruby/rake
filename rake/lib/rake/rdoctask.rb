#!/usr/bin/env ruby

require 'rake/filelist'

module Rake

  class RDocTask
    attr_accessor :name, :rdoc_dir, :main, :template
    attr_reader :rdoc_files, :options

    def initialize(name=:rdoc)
      @name = name
      @rdoc_files = Rake::FileList.new
      @rdoc_dir = 'html'
      @main = 'README'
      @template = 'html'
      @options = []
      yield self if block_given?
    end
    
    def define
      desc "Build the RDOC HTML Files"
      task :rdoc
      
      desc "Force a rebuild of the RDOC files"
      task :rerdoc => [:clean_rdoc, :rdoc]
      
      desc "Remove rdoc products" 
      task :clobber_rdoc do
	rm_r rdoc_dir rescue nil
      end

      task :clobber => [:clobber_rdoc]
      
      directory @rdoc_dir
      task :rdoc => [rdoc_target]
      file rdoc_target => @rdoc_files + ["Rakefile"] do
	rm_r @rdoc_dir rescue nil
	sh %{rdoc -o #{@rdoc_dir} #{@options} --main #{main} -T #{template} #{@rdoc_files}}
      end
    end
    
    private
    
    def rdoc_target
      "#{rdoc_dir}/index.html"
    end
  end
end

    
