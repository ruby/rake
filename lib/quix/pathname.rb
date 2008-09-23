
require 'quix/builtin/kernel/tap'
require 'pathname'

module Quix
  module Pathname
    def ext(new_ext)
      sub(%r!#{extname}\Z!, ".#{new_ext}")
    end
    
    def stem
      sub(%r!#{extname}\Z!, "")
    end

    def explode
      to_s.split(::Pathname::SEPARATOR_PAT).map { |path|
        ::Pathname.new path
      }
    end

    module Meta
      def join(*paths)
        ::Pathname.new File.join(*paths)
      end
    end
  end
end

