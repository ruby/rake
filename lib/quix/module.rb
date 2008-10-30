
#
# Module#private with optional block
#

class Module
  alias_method :private__original, :private
  def private(*args, &block)
    private__original(*args)
    if block
      singleton_class = (class << self ; self ; end)
      caller_self = block.binding.eval("self")
      method_added__original =
        if (t = method(:method_added)) and t.owner == singleton_class
          t
        else
          nil
        end
      begin
        singleton_class.instance_eval {
          define_method(:method_added) { |name|
            caller_self.instance_eval {
              private__original(name.to_sym)
            }
            if t = method_added__original
              t.call(name)
            end
          }
        }
        block.call
      ensure
        if t = method_added__original
          t.owner.instance_eval {
            define_method(:method_added, t)
          }
        else
          singleton_class.instance_eval {
            remove_method(:method_added)
          }
        end
      end
    end
  end
end

#
# Module#include which warns on replaced methods
#

if $DEBUG and !(defined?($NO_DEBUG_INCLUDE) and $NO_DEBUG_INCLUDE)
  class Module
    orig_include = instance_method(:include)
    remove_method(:include)
    define_method(:include) { |*mods|
      mods.each { |mod|
        if mod.class == Module
          mod.instance_methods(true).each { |name|
            if self.instance_methods(true).include?(name)
              STDERR.puts("Note: replacing #{self.inspect}##{name} " +
                "with #{mod.inspect}##{name}")
            end
          }
        end
        orig_include.bind(self).call(*mods)
      }
    }
  end
end

