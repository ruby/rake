$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"

require 'quix/reverse_range'

begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  require 'spec'
end

if RUBY_VERSION < "1.8.7"
  require 'enumerator'
  class Integer
    def pred
      self - 1
    end
  end
end

ReverseRange = Quix::ReverseRange

######################################################################
# common
######################################################################

def check_expression(&block)
  statement = block.call
  eval(
    statement.
    sub("==", ".should==").
    sub("!=", ".should_not=="),
       
    block.binding)
end

def equation(statement)
  unless match = statement.match(%r!\A\s*(.*?)\s*==\s*(.*?)\s*\Z!)
    raise
  end
  it "#{match[1]}  #=> #{match[2]}" do |t|
    check_expression { statement }
  end
end

def it_has_invariant(inv)
  it "has invariant #{inv}" do |t|
    r = @range
    check_expression { inv }
  end
end

######################################################################
# description
######################################################################

describe "Synopsis" do
  equation "(3..7).to_a == [3, 4, 5, 6, 7]"
  equation "(7..3).to_a == []"
  equation "reversible(3..7).to_a == [3, 4, 5, 6, 7]"
  equation "reversible(7..3).to_a == [7, 6, 5, 4, 3]"
end

describe "A forward-pointing Range (3..7) with r.exclude_end? == false" do
  setup do
    @range = 3..7
  end

  it_has_invariant "reversible(r) == r"
  it_has_invariant "reversible(r).object_id == r.object_id"
end

describe "A backward-pointing Range (7..3) with r.exclude_end? == false" do
  setup do
    @range = 7..3
  end

  it_has_invariant "reversible(r) == ReverseRange.new(r.begin, r.end)"
end

describe "A forward-pointing Range (3...7) with r.exclude_end? == true" do
  setup do
    @range = 3...7
  end

  it "is accepted by reversible()" do
    lambda { reversible(@range) }.should_not raise_error
  end
end
    
describe "A backward-pointing Range (7...3) with r.exclude_end? == true" do
  setup do
    @range = 7...3
  end

  it "is rejected by reversible()" do
    lambda { reversible(@range) }.should raise_error(ArgumentError)
  end
end

describe "ReverseRange" do
  setup do
    @range = ReverseRange.new(7, 3)
  end

  describe "instances are normally created with reversible()" do
    equation "reversible(7..3) == ReverseRange.new(7, 3)"
  end

  describe "behaves similarly to Range" do
    equation "reversible(7..3).inspect == '#<ReverseRange 7..3>'"
    equation "reversible(7..3).first == 7"
    equation "reversible(7..3).last == 3"
    equation "reversible(7..3).include?(9) == false"
    equation "reversible(7..3).member?(4) == true"
    equation "reversible(7..3).include?(4) == true"
    equation "(7..3).include?(4) == false"

    it "has the same case/when semantics as Range" do
      inside = lambda { |i|
        @range === i
      }
  
      outside = lambda { |i|
        not (@range === i)
      }
  
      @range.begin.downto(@range.end, &inside)
      100.downto(@range.begin + 1, &outside)
      0.upto(@range.end - 1, &outside)
    end
  end

  describe "can also be passed to reversible()" do
    equation "ReverseRange.new(3, 7).to_a == []"
    equation "reversible(ReverseRange.new(3, 7)).to_a == [3, 4, 5, 6, 7]"
    equation "reversible(ReverseRange.new(3, 7)).is_a?(Range) == true"
    equation "reversible(ReverseRange.new(7, 3)).is_a?(ReverseRange) == true"
  end

  describe "#step(n)" do
    it "argument n must be negative" do
      lambda { @range.step(-4) { } }.should_not raise_error
      lambda { @range.step(0) { } }.should raise_error(ArgumentError)
      lambda { @range.step(4) { } }.should raise_error(ArgumentError)
    end
    
    equation "reversible(7..3).to_enum(:step, -1).to_a == [7, 6, 5, 4, 3]"
    equation "reversible(7..3).to_enum(:step, -2).to_a == [7, 5, 3]"
    equation "reversible(7..3).to_enum(:step, -3).to_a == [7, 4]"
    equation "reversible(7..3).to_enum(:step, -4).to_a == [7, 3]"
    equation "reversible(7..3).to_enum(:step, -5).to_a == [7]"
    equation "reversible(7..3).to_enum(:step, -99).to_a == [7]"

    describe "with simple one-character String#pred" do
      before(:each) do
        String.class_eval {
          def pred
            self[0].pred.chr
          end
        }
      end

      after(:each) do
        String.class_eval {
          remove_method :pred
        }
      end

      equation "reversible('t'..'p').to_enum(:step, -1).to_a == %w[t s r q p]"
      equation "reversible('t'..'p').to_enum(:step, -2).to_a == %w[t r p]"
      equation "reversible('t'..'p').to_enum(:step, -3).to_a == %w[t q]"
      equation "reversible('t'..'p').to_enum(:step, -4).to_a == %w[t p]"
      equation "reversible('t'..'p').to_enum(:step, -5).to_a == %w[t]"
      equation "reversible('t'..'p').to_enum(:step, -99).to_a == %w[t]"
    end
  end

  describe "details" do
    it_has_invariant "r == r"
    it_has_invariant "r == ReverseRange.new(r.begin, r.end)"
    it_has_invariant "r.eql?(r) == true"
    it_has_invariant "r.eql?(ReverseRange.new(r.begin, r.end)) == true"
    it_has_invariant "r.exclude_end? == false"
    it_has_invariant "r.inspect == r.to_s"
    
    it "calls #pred on elements" do
      1.should == 1
    end

    it "leaves #pred definition to the user" do
      lambda { reversible("z".."a").to_a }.
        should raise_error(NoMethodError)
    end
  end
end

describe "reversible()" do
  it "accepts Range object" do
    lambda { reversible(3..7) }.should_not raise_error
  end

  it "accepts Range-quacking object" do
    mock = Class.new {
      def begin ; 2 ; end
      def end ; 1 ; end
      def exclude_end? ; false ; end
    }.new
    lambda { reversible(mock) }.should_not raise_error
  end

  it "fails if argument does not quack like Range" do
    lambda { reversible(1) }.should raise_error
    lambda { reversible(1, 2) }.should raise_error
    lambda { reversible("foo") }.should raise_error
    lambda { reversible(Object.new) }.should raise_error
  end
end



