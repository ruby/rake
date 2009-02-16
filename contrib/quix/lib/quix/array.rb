
class Array
  [
   nil,
   :second,
   :third,
   :fourth,
   :fifth,
   :sixth,
   :seventh,
   :eighth,
   :ninth,
   :tenth,
  ].each_with_index { |name, index|
    if name
      define_method(name) {
        self[index]
      }
    end
  }

  def penultimate
    self[-2]
  end

  alias_method :head, :first

  def tail
    self[1..-1]
  end

  def inject1(&block)
    tail.inject(head, &block)
  end
end
