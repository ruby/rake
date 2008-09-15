
module Quix
  module File
    def stemname(file)
      file.sub(%r!#{::File.extname(file)}\Z!, "")
    end

    extend self
  end
end
