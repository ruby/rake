
require 'tmpdir'
require 'quix/kernel'

module FileUtils
  module_function

  def rename_file(file, new_name)
    #
    # For case-insensitive systems, we must move the file elsewhere
    # before changing case.
    #
    temp = File.join(Dir.tmpdir, File.basename(file))
    mv(file, temp)
    begin
      mv(temp, new_name)
    rescue
      mv(temp, file)
      raise
    end
  end
  
  def replace_file(file, opts = {})
    old_contents = File.read(file)
    yield(old_contents).tap { |new_contents|
      if opts[:force] or old_contents != new_contents
        File.open(file, "w") { |output|
          output.print(new_contents)
        }
      end
    }
  end
end
