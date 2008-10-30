$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib"

require 'test/unit'
require 'quix/pathname'

class TestPathname < Test::Unit::TestCase
  def test_ext
    assert_equal("a/b/c.o", Pathname.new("a/b/c.rb").ext("o").to_s)
    assert_equal("c.o", Pathname.new("c.f").ext("o").to_s)
  end

  def test_stem
    assert_equal("a/b/c", Pathname.new("a/b/c.rb").stem.to_s)
    assert_equal("a.b", Pathname.new("a.b.c").stem.to_s)
  end

  def test_explode
    path = Pathname.new "a/b/c/d.h"
    assert_equal(%w(a b c d.h).map { |t| Pathname.new t }, path.explode)
  end

  def test_join
    path = Pathname.new "a/b/c/d.h"
    assert_equal(
      Pathname.new("b/c/d.h"),
      Pathname.join(*path.explode[1..-1]))
  end
end
