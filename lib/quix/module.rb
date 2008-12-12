
class Module
  def define_module_function(name, &block)
    define_method(name, &block)
    module_function(name)
  end
end
