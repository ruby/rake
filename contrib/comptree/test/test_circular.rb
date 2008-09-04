$LOAD_PATH.unshift(File.expand_path("#{File.dirname(__FILE__)}/../lib"))

require 'comptree'
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

        assert_raises(CircularError) {
          driver.check_circular(:area)
        }
      }
    end
  end
end
