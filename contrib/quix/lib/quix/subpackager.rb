
require 'quix/hash_struct'

module Quix
  module Subpackager
    WARNING = %q{


      ######################################################
      # 
      # **** DO NOT EDIT ****
      # 
      # **** THIS IS A GENERATED FILE *****
      # 
      ######################################################


    }.gsub(%r!^ +!, "")
  
    def self.run(packages, warning = WARNING)
      HashStruct.recursive_new(packages).each_pair { |pkg, pkg_spec|
        pkg_spec.subpackages.each_pair { |subpkg, subpkg_spec|
          process_path = lambda { |path|
            source = "#{subpkg_spec.lib_dir}/#{path}.rb"
            dest = "#{pkg_spec.lib_dir}/#{pkg}/#{path}.rb"
    
            contents =
              WARNING +
              File.read(source).gsub(%r!require [\'\"]#{subpkg}!) {
                |match|
                match.sub(%r!#{subpkg}\Z!, "#{pkg}/#{subpkg}")
              }.gsub(subpkg_spec.name_in_ruby) {
                "#{pkg_spec.name_in_ruby}::#{subpkg_spec.name_in_ruby}"
              } +
              WARNING
            
            mkdir_p(File.dirname(dest))
            puts "#{source} --> #{dest}"
            File.open(dest, "w") { |t| t.print(contents) }
          }

          unless subpkg_spec.ignore_root_rb
            process_path.call(subpkg)
          end
          subpkg_spec.sources.each { |path|
            process_path.call("#{subpkg}/#{path}")
          }
        }
      }
    end
  end
end
