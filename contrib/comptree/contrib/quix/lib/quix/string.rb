
require 'quix/builtin/kernel/tap'

module Quix
  module String
    def trim_left!
      sub!(%r!\A\s+!, "")
    end

    def trim_right!
      sub!(%r!\s+\Z!, "")
    end

    def trim!
      result_left = trim_left!
      result_right = trim_left!
      result_left || result_right
    end

    def trim_left
      clone.tap { |result|
        result.trim_left!
      }
    end

    def trim_right
      clone.tap { |result|
        result.trim_right!
      }
    end

    def trim
      clone.tap { |result|
        result.trim!
      }
    end
  end
end
