
require 'tmpdir'
require 'quix/builtin/kernel/tap'

module Quix
  module FileUtils
    def rename_file(file, new_name)
      #
      # For case-insensitive systems, we must move the file elsewhere
      # before changing case.
      #
      temp = ::File.join(Dir.tmpdir, ::File.basename(file))
      ::FileUtils.mv(file, temp)
      begin
        ::FileUtils.mv(temp, new_name)
      rescue
        ::FileUtils.mv(temp, file)
        raise
      end
    end
    
    def replace_file(file)
      old_contents = ::File.read(file)
      yield(old_contents).tap { |new_contents|
        ::File.open(file, "w") { |output|
          output.print(new_contents)
        }
      }
    end
    
    def stem(file)
      file.sub(%r!#{::File.extname(file)}\Z!, "")
    end

    extend self
  end
end
