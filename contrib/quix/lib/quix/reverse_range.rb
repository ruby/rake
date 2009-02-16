
module Kernel
  private
  def reversible(range)
    if range.is_a? Quix::ReverseRange
      if (range.begin <=> range.end) == -1
        Range.new(range.begin, range.end)
      else
        range
      end
    elsif (range.begin <=> range.end) == 1
      if range.exclude_end?
        raise ArgumentError,
          "reversible() argument cannot have exclude_end? == false"
      else
        Quix::ReverseRange.new(range.begin, range.end)
      end
    else
      range
    end
  end
end

module Quix
  class ReverseRange
    include Enumerable
  
    def initialize(high, low)
      @begin, @end = high, low
    end
  
    attr_reader :begin, :end
  
    def each
      elem = @begin
      while (elem <=> @end) != -1  # operator >=
        yield elem
        elem = elem.pred
      end
    end
  
    def ==(other)
      if object_id == other.object_id
        true
      else
        other.is_a?(ReverseRange) and
        (self.begin == other.begin) and
        (self.end == other.end)
      end
    end
    
    def eql?(other)
      if object_id == other.object_id
        true
      else
        other.is_a?(ReverseRange) and
        (self.begin.eql? other.begin) and
        (self.end.eql? other.end)
      end
    end
  
    def exclude_end?
      false
    end
  
    def include?(elem)
      a = (elem <=> self.begin)
      b = (elem <=> self.end)
  
      (a == 0 or b == 0) or
      (a == -1 and b == 1)
    end
  
    def step(n = -1)
      n = n.is_a?(Numeric) ? n.to_int : n
  
      if n > 0
        raise ArgumentError, "step can't be positive"
      elsif n == 0
        raise ArgumentError, "step can't be zero"
      end
      
      elem = @begin
  
      if @begin.is_a?(Numeric) and @end.is_a?(Numeric)
        while elem > @end - 1
          yield elem
          elem += n
        end
      else
        while (elem <=> @end) != -1  # operator >=
          yield elem
          (-n).times {
            elem = elem.pred
          }
        end
      end
    end
  
    def to_s
      "#<ReverseRange #{@begin}..#{@end}>"
    end
  
    alias_method :first, :begin
    alias_method :last, :end
    alias_method :inspect, :to_s
    alias_method :===, :include?
    alias_method :member?, :include?
  end
end
