
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

