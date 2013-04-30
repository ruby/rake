module Rake

  ####################################################################
  # InvocationChain tracks the chain of task invocations to detect
  # circular dependencies.
  class InvocationChain < LinkedList
    def member?(obj)
      head == obj || tail.member?(obj)
    end

    def append(value)
      if member?(value)
        fail RuntimeError, "Circular dependency detected: #{to_s} => #{value}"
      end
      self.class.new(value, self)
    end

    def to_s
      "#{prefix}#{head}"
    end

    def self.append(value, chain)
      chain.append(value)
    end

    def self.empty
      EMPTY
    end

    private

    def prefix
      "#{tail.to_s} => "
    end

    class EmptyInvocationChain < LinkedList::EmptyLinkedList
      def member?(obj)
        false
      end

      def append(value)
        InvocationChain.new(value, self)
      end

      def to_s
        "TOP"
      end
    end

    EMPTY = EmptyInvocationChain.new
  end
end
