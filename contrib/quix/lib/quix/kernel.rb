
require 'thread'

module Quix
  module Kernel
    def scope
      yield self
    end

    def singleton_class
      class << self
        self
      end
    end

    def gensym(prefix = nil)
      count = Quix::Kernel.instance_eval {
        Thread.exclusive {
          @private__gensym_count ||= 0
          @private__gensym_count += 1
        }
      }
      :"#{prefix || :G}_#{count}_#{rand}"
    end

    def call_private(method, *args, &block)
      instance_eval { send(method, *args, &block) }
    end

    # execute a block with warnings turned off
    def no_warnings
      Thread.exclusive {
        previous_verbose = $VERBOSE
        begin
          $VERBOSE = nil
          yield
        ensure
          $VERBOSE = previous_verbose
        end
      }
    end

    extend self
  end
end
