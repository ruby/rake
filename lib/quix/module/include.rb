
#
# warns when methods are replaced
#
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
