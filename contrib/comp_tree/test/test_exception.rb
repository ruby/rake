
#
# Mean workaround using separate processes due to assert_raise causing
# problems with threads.
#

require 'test/unit'

module WorkaroundConfig
  HERE = File.dirname(__FILE__)
  LIB_DIR = File.expand_path("#{HERE}/../lib")
  QUIX_LIB_DIR = File.expand_path("#{HERE}/../contrib/quix/lib")
  OUTPUT_FILE = "#{HERE}/#{File.basename(__FILE__)}.output"
  
  $LOAD_PATH.unshift LIB_DIR
  $LOAD_PATH.unshift QUIX_LIB_DIR
end
  
require 'comp_tree'
require 'quix/config'

module CompTree
  class TestRaises < Test::Unit::TestCase
    include WorkaroundConfig

    def test_exception
      if RUBY_PLATFORM =~ %r!java!
        puts "skipping #{File.basename(__FILE__)}."
      else
        [true, false].each { |use_fork|
          [true, false].each { |define_all|
            assert(
              !system(
                ::Quix::Config.ruby_executable,
                "-e",
                code(use_fork, define_all)))
            
            output = File.read(OUTPUT_FILE)

            if define_all
              assert_match(%r!CompTreeTestError!, output)
            else
              assert_match(%r!NoFunctionError!, output)
            end
            
            File.unlink(OUTPUT_FILE) # leave when exception raised above
          }
        }
      end
    end

    def code(use_fork, define_all)
      %Q( 
        $LOAD_PATH.unshift '#{LIB_DIR}'
        require 'comp_tree'
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
      ) +    
      if define_all
        %Q(
          driver.define(:border) {
            raise CompTreeTestError
          }
        )
      else
        ""
      end +
      %Q(        
          driver.define(:offset) {
            7
          }
          
          File.open('#{OUTPUT_FILE}', "w") { |out|
            $stderr = out
            driver.compute(
              :area, :threads => 99, :fork => #{use_fork.inspect})
          }
        }
      )
    end
  end
end 
