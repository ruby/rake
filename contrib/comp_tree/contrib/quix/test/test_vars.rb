$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'quix/vars'
require 'quix/hash_struct'

class TestVars < Test::Unit::TestCase
  include Quix::Vars

  def test_locals_to_hash
    a = 33
    b = Object.new
    c = lambda { a + 11 }

    hash = locals_to_hash {%{a, b, c}}

    assert_equal(a.object_id, hash[:a].object_id)
    assert_equal(b.object_id, hash[:b].object_id)
    assert_equal(c.object_id, hash[:c].object_id)

    assert_equal(hash[:c].call, 44)
  end

  def test_hash_to_locals
    a = nil
    b = nil
    c = nil
    
    hash = {
      :a => 33,
      :b => Object.new,
      :c => lambda { hash[:a] + 11 },
    }

    hash_to_locals { hash }

    assert_equal(a.object_id, hash[:a].object_id)
    assert_equal(b.object_id, hash[:b].object_id)
    assert_equal(c.object_id, hash[:c].object_id)

    assert_equal(hash[:c].call, 44)
    assert_nothing_raised { hash_to_locals { nil } }
  end

  def test_with_readers
    hash = {
      :a => 33,
      :b => Object.new,
      :c => lambda { hash[:a] + 11 },
    }

    assert_raise(NameError) { a }
    assert_raise(NameError) { b }
    assert_raise(NameError) { c }

    with_readers(hash) {
      assert_equal(a.object_id, hash[:a].object_id)
      assert_equal(b.object_id, hash[:b].object_id)
      assert_equal(c.object_id, hash[:c].object_id)
    }

    assert_raise(NameError) { a }
    assert_raise(NameError) { b }
    assert_raise(NameError) { c }

    with_readers(hash, :a, :b) {
      assert_equal(a.object_id, hash[:a].object_id)
      assert_equal(b.object_id, hash[:b].object_id)
      assert_raise(NameError) { c }
    }
  end

  def test_locals_to_ivs
    a = 33
    b = Object.new
    c = lambda { a + 11 }

    assert(!defined?(@a))
    assert(!defined?(@b))
    assert(!defined?(@c))
    
    locals_to_ivs {%{a, b, c}}

    assert_equal(a.object_id, @a.object_id)
    assert_equal(b.object_id, @b.object_id)
    assert_equal(c.object_id, @c.object_id)

    assert_equal(@c.call, 44)
  end

  def test_hash_to_ivs
    hash = {
      :d => 33,
      :e => Object.new,
      :f => lambda { hash[:d] + 11 },
    }

    assert(!defined?(@d))
    assert(!defined?(@e))
    assert(!defined?(@f))
    
    hash_to_ivs { hash }

    assert_equal(hash[:d].object_id, @d.object_id)
    assert_equal(hash[:e].object_id, @e.object_id)
    assert_equal(hash[:f].object_id, @f.object_id)

    assert_equal(hash[:f].call, 44)
    assert_nothing_raised { hash_to_ivs { nil } }
  end

  def test_config_to_hash
    config = %q{
      a = 33
      b = a + 11
      c = 5*(a - 22)
      d = (1..3).map { |n| n*n }
      e = "moo"
      f = lambda { a + 66 }

      a_object_id = a.object_id
      b_object_id = b.object_id
      c_object_id = c.object_id
      d_object_id = d.object_id
      e_object_id = e.object_id
      f_object_id = f.object_id
    }

    hash = config_to_hash(config)

    assert_equal(hash[:a], 33)
    assert_equal(hash[:b], 44)
    assert_equal(hash[:c], 55)
    assert_equal(hash[:d], [1, 4, 9])
    assert_equal(hash[:e], "moo")
    assert_equal(hash[:f].call, 99)

    assert_equal(hash[:a].object_id, hash[:a_object_id])
    assert_equal(hash[:b].object_id, hash[:b_object_id])
    assert_equal(hash[:c].object_id, hash[:c_object_id])
    assert_equal(hash[:d].object_id, hash[:d_object_id])
    assert_equal(hash[:e].object_id, hash[:e_object_id])
    assert_equal(hash[:f].object_id, hash[:f_object_id])
  end

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
