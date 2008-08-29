
require 'ostruct'
require 'quix/builtin/kernel/tap'

module Quix
  #
  # An OpenStruct with the ability to define lazily-evaluated fields.
  #
  class LazyStruct < OpenStruct
    #
    # For mixing into an existing OpenStruct instance singleton class.
    #
    module Mixin
      #
      # &block is evaluated when this attribute is requested.  The
      # same result is returned for subsquent calls, until the field
      # is assigned a different value.
      #
      def attribute(reader, &block)
        singleton = (class << self ; self ; end)
        singleton.instance_eval {
          #
          # Define a special reader method in the singleton class.
          #
          define_method(reader) {
            block.call.tap { |value|
              #
              # The value has been computed.  Replace this method with a
              # one-liner giving the value.
              #
              singleton.instance_eval {
                remove_method(reader)
                define_method(reader) { value }
              }
            }
          }
          
          #
          # Revert to the old OpenStruct behavior when the writer is called.
          #
          writer = "#{reader}=".to_sym
          define_method(writer) { |value|
            singleton.instance_eval {
              remove_method(reader)
              remove_method(writer)
            }
            method_missing(writer, value)
          }
        }
      end
    end
    
    include Mixin
  end
end
