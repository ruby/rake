
require 'thread'
require 'quix/kernel'

module Quix
  class ThreadLocal
    def initialize(prefix = nil, &default)
      @name = gensym(prefix)
      @accessed = gensym(prefix)
      @default = default
    end
    
    def value
      t = Thread.current
      unless t[@accessed]
        if @default
          t[@name] = @default.call
        end
        t[@accessed] = true
      end
      t[@name]
    end
    
    def value=(value)
      t = Thread.current
      t[@accessed] = true
      t[@name] = value
    end
  end
end
