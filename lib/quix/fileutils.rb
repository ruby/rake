
require 'tmpdir'
require 'quix/kernel'

module FileUtils
  def rename_file(file, new_name)
    #
    # For case-insensitive systems, we must move the file elsewhere
    # before changing case.
    #
    temp = File.join(Dir.tmpdir, File.basename(file))
    ::FileUtils.mv(file, temp)
    begin
      ::FileUtils.mv(temp, new_name)
    rescue
      ::FileUtils.mv(temp, file)
      raise
    end
  end
  module_function :rename_file
  
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
  module_function :replace_file

end
