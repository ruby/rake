
require 'test/unit'

module CompTree
  class TestRaises < Test::Unit::TestCase
    HERE = File.dirname(__FILE__)
    LIB_DIR = File.expand_path("#{HERE}/../lib")
    QUIX_LIB_DIR = File.expand_path("#{HERE}/../contrib/quix/lib")

    OUTPUT_FILE = "#{HERE}/#{File.basename(__FILE__)}.output"
    
    $LOAD_PATH.unshift LIB_DIR
    $LOAD_PATH.unshift QUIX_LIB_DIR
    
    require 'quix/config'

    def test_1
      if RUBY_PLATFORM =~ %r!java!
        puts "skipping #{File.basename(__FILE__)}."
      else
        [true, false].each { |use_fork|
          assert(!system(Quix::Config.ruby_executable, "-e", code(use_fork)))
          assert_match(%r!CompTreeTestError!, File.read(OUTPUT_FILE))
          File.unlink(OUTPUT_FILE) # leave when exception raised above
        }
      end
    end

    def code(use_fork)
      %Q{ 
        $LOAD_PATH.unshift '#{LIB_DIR}'
        require 'comptree'
        require 'open3'
        
        class CompTreeTestError < Exception ; end
        
        CompTree::Driver.new { |driver|
          driver.define(:area, :width, :height, :offset) {
            |width, height, offset|
            width*height - offset
          }
          
          driver.define(:width, :border) { |border|
            2 + border
          }
          
          driver.define(:height, :border) { |border|
            3 + border
          }
          
          driver.define(:border) {
            raise CompTreeTestError
          }
              
          driver.define(:offset) {
            7
          }
          
          File.open('#{OUTPUT_FILE}', "w") { |out|
            $stderr = out
            driver.compute(
              :area, :threads => 99, :fork => #{use_fork.inspect})
          }
        }
      }
    end
  end
end 
