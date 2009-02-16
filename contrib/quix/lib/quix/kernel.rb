
require 'thread'

module CompTree
  module Misc
    module_function

    def let
      yield self
    end

    def singleton_class
      class << self
        self
      end
    end

    module Gensym
      @mutex = Mutex.new
      @count = 0

      def gensym(prefix = nil)
        count = Gensym.module_eval {
          @mutex.synchronize {
            @count += 1
          }
        }
        "#{prefix || :G}_#{count}".to_sym
      end
    end
    include Gensym

    def call_private(method, *args, &block)
      instance_eval { send(method, *args, &block) }
    end

    def with_warnings(value = true)
      previous = $VERBOSE
      $VERBOSE = value
      begin
        yield
      ensure
        $VERBOSE = previous
      end
    end

    def no_warnings(&block)
      with_warnings(false, &block)
    end

    def loop_with(done, restart)
      catch(done) {
        while true
          catch(restart) {
            yield
          }
        end
      }
    end
  end
end
