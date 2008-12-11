$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'quix/hash_struct'

class TestHashStruct < Test::Unit::TestCase
  def test_read_write
    s = Quix::HashStruct.new

    s.a = 33
    assert_equal(s.a, s[:a])
    assert_equal(s.a.object_id, s[:a].object_id)
    assert_equal(33, s[:a])

    s[:b] = 44.0
    assert_equal(s.b, s[:b])
    assert_equal(s.b.object_id, s[:b].object_id)
    assert_equal(44.0, s[:b])

    s.delete(:b)
    assert_equal(nil, s[:b])
    assert_equal(nil, s.b)
  end

  def test_recursive_new
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

