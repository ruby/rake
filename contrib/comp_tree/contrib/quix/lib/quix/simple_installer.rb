
require 'rbconfig'
require 'fileutils'
require 'find'
require 'fileutils'
require 'quix/vars'
  
module Quix
  class SimpleInstaller
    include Quix::Vars

    def initialize
      dest_root = Config::CONFIG["sitelibdir"]
      sources = []
      Find.find("./lib") { |source|
        if install_file?(source)
          sources << source
        end
      }
      @spec = sources.inject(Array.new) { |acc, source|
        if source == "./lib"
          acc
        else
          dest = File.join(dest_root, source.sub(%r!\A\./lib!, ""))
  
          install = lambda {
            if File.directory?(source)
              unless File.directory?(dest)
                puts "mkdir #{dest}"
                FileUtils.mkdir(dest)
              end
            else
              puts "install #{source} --> #{dest}"
              FileUtils.install(source, dest)
            end
          }
            
          uninstall = lambda {
            if File.directory?(source)
              if File.directory?(dest)
                puts "rmdir #{dest}"
                FileUtils.rmdir(dest)
              end
            else
              if File.file?(dest)
                puts "rm #{dest}"
                FileUtils.rm(dest)
              end
            end
          }
  
          acc << locals_to_hash {%{source, dest, install, uninstall}}
        end
      }
    end
  
    def install_file?(source)
      !File.symlink?(source) and
        (File.directory?(source) or
          (File.file?(source) and File.extname(source) == ".rb"))
    end

    attr_accessor :spec

    def install
      @spec.each { |entry|
        entry[:install].call
      }
    end
  
    def uninstall
      @spec.reverse.each { |entry|
        entry[:uninstall].call
      }
    end

    def run(args = ARGV)
      if args.empty? or (args.size == 1 and args.first == "install")
        install
      elsif args.size == 1 and args.first == "uninstall"
        uninstall
      else
        raise "unrecognized arguments: #{args.inspect}"
      end
    end
  end
end
