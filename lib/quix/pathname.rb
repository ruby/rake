
require 'pathname'

module Quix
  module Pathname
    def ext(new_ext)
      sub(%r!#{extname}\Z!, ".#{new_ext}")
    end
    
    def stem
      sub(%r!#{extname}\Z!, "")
    end
  end
end

