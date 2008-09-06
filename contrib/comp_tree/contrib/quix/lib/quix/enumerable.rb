
require 'quix/builtin/kernel/tap'

module Quix
  module Enumerable
    def inject_with_index(*args)
      index = 0
      inject(*args) { |acc, elem|
        yield(acc, elem, index).tap {
            index += 1
        }
      }
    end

    def map_with_index
      Array.new.tap { |result|
        each_with_index { |elem, index|
          result << yield(elem, index)
        }
      }
    end

    def select_with_index
      Array.new.tap { |result|
        each_with_index { |elem, index|
          if yield(elem, index)
            result << elem
          end
        }
      }
    end
  end
end
