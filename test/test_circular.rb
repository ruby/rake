$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"

require 'comp_tree'
require 'test/unit'

module CompTree
  class TestCircular < Test::Unit::TestCase
    def test_1
      CompTree::Driver.new { |driver|
        driver.define(:area, :width, :height, :offset) { |width, height, offset|
          width*height - offset
        }
        
        driver.define(:width, :border) { |border|
          2 + border
        }
        
        driver.define(:height, :border) { |border|
          3 + border
        }
        
        driver.define(:border) {
          5
        }
        
        driver.define(:offset, :area) {
          7
        }

        assert_raises(Error::CircularError) {
          driver.check_circular(:area)
        }
      }
    end
  end
end
