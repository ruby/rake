module Rake

  class LinkedList
    include Enumerable

    attr_reader :head, :tail

    def initialize(head, tail=EMPTY)
      @head = head
      @tail = tail
    end

    def conj(item)
      self.class.cons(item, self)
    end

    def empty?
      false
    end

    def ==(other)
      current = self
      while ! current.empty? && ! other.empty?
        return false if current.head != other.head
        current = current.tail
        other = other.tail
      end
      current.empty? && other.empty?
    end

    def to_s
      items = map { |item| item.to_s }.join(", ")
      "LL(#{items})"
    end

    def inspect
      items = map { |item| item.inspect }.join(", ")
      "LL(#{items})"
    end

    def each
      current = self
      while ! current.empty?
        yield(current.head)
        current = current.tail
      end
      self
    end

    def self.make(*args)
      result = empty
      args.reverse_each do |item|
        result = cons(item, result)
      end
      result
    end

    def self.cons(head, tail)
      new(head, tail)
    end

    def self.empty
      self::EMPTY
    end

    def self.parent
      empty.parent
    end

    class EmptyLinkedList < LinkedList
      def initialize(parent)
        self.class.parent = parent
      end

      def empty?
        true
      end

      def self.cons(head, tail)
        @parent.cons(head, tail)
      end

      def self.parent=(parent)
        @parent = parent
      end
    end

    EMPTY = EmptyLinkedList.new(self)
  end

end
