#!/usr/bin/env ruby

require 'test/unit'
require 'rake/filelist'

class TestFileList < Test::Unit::TestCase
  def test_create
    fl = Rake::FileList.new
    assert_equal 0, fl.size
  end

  def test_add
    fl = Rake::FileList.new
    fl << "a.rb" << "b.rb"
    assert_equal ['a.rb', 'b.rb'], fl
  end

  def test_add_many
    fl = Rake::FileList.new
    fl.add %w(a d c )
    fl.add('x', 'y')
    assert_equal ['a', 'd', 'c', 'x', 'y'], fl
  end

  def test_match
    fl = Rake::FileList.new
    fl.add('test/test*.rb')
    assert fl.include?("test/testfilelist.rb")
    assert fl.size > 3
    fl.each { |fn| assert_match /\.rb$/, fn }
  end

  def test_add_matching
    fl = Rake::FileList.new
    fl << "a.java"
    fl.add("test/*.rb")
    assert_equal "a.java", fl[0]
    assert fl.size > 2
    assert fl.include?("test/testfilelist.rb")
  end

  def test_multiple_patterns
    fl = Rake::FileList.new
    fl.add('*.c', '*xist*')
    assert_equal [], fl
    fl.add('testdata/*.c', 'testdata/*xist*')
    assert_equal [
      'testdata/x.c', 'testdata/xyz.c', 'testdata/abc.c', 'testdata/existing'
    ].sort, fl.sort
  end

  def test_reject
    fl = Rake::FileList.new
    fl.add %w(testdata/x.c testdata/abc.c testdata/xyz.c testdata/existing)
    fl.reject! { |fn| fn =~ %r{/x} }
    assert_equal [
      'testdata/abc.c', 'testdata/existing'
    ], fl
  end

  def test_unique
    fl = Rake::FileList.new
    fl << "x.c" << "a.c" << "b.rb" << "a.c"
    assert_equal ['x.c', 'a.c', 'b.rb', 'a.c'], fl
    fl.uniq!
    assert_equal ['x.c', 'a.c', 'b.rb'], fl
  end

  def test_to_string
    fl = Rake::FileList.new
    fl << "a.java" << "b.java"
    assert_equal  "a.java b.java", fl.to_s
    assert_equal  "a.java b.java", "#{fl}"
  end

end
