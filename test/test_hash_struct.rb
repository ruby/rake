$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'quix/hash_struct'

class TestHashStruct < Test::Unit::TestCase
  def test_hash_struct
    hash = {
      :a => {
        :b => :c,
        :d => :e,
        :f => {
          :g => :h,
          :i => :j,
        },
      },
      :k => :l,
      :m => [ :n, :o, :p ],
      :q => {
        :r => {},
        :s => [],
      },
      :t => [
        {
          :u => :v,       
          :w => :x,       
        },
      ],
      :w => {
        :x => {
          :y => :z,
        },
      },
    }
    
    s = Quix::HashStruct.recursive_new(hash)
    assert_equal(s.a.b, :c)
    assert_equal(s.a.d, :e)
    assert_equal(s.a.f.g, :h)
    assert_equal(s.a.f.i, :j)
    assert_equal(s.k, :l)
    assert_equal(s.m, [:n, :o, :p])
    assert_equal(s.q.r, OpenStruct.new)
    assert_equal(s.q.s, [])
    assert_equal(s.t, [{ :u => :v, :w => :x }])
    assert_equal(s.w.x.y, :z)
  end
end

