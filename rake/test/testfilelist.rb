#!/usr/bin/env ruby

require 'test/unit'
require 'rake/filelist'

class TestFileList < Test::Unit::TestCase
  FileList = Rake::FileList

  def test_create
    fl = FileList.new
    assert_equal 0, fl.size
  end

  def test_create_with_args
    create_test_data
    fl = FileList.new("testdata/*.c", "x")
    assert_equal ["testdata/abc.c", "testdata/x.c", "testdata/xyz.c", "x"].sort,
      fl.sort
  end

  def test_create_with_brackets
    create_test_data
    fl = FileList["testdata/*.c", "x"]
    assert_equal ["testdata/abc.c", "testdata/x.c", "testdata/xyz.c", "x"].sort,
      fl.sort
  end

  def test_append
    fl = FileList.new
    fl << "a.rb" << "b.rb"
    assert_equal ['a.rb', 'b.rb'], fl
  end

  def test_add_many
    fl = FileList.new
    fl.add %w(a d c )
    fl.add('x', 'y')
    assert_equal ['a', 'd', 'c', 'x', 'y'], fl
  end

  def test_add_return
    f = FileList.new
    g = f << "x"
    assert_equal f.id, g.id
    h = f.add("y")
    assert_equal f.id, h.id
  end
  
  def test_match
    fl = FileList.new
    fl.add('test/test*.rb')
    assert fl.include?("test/testfilelist.rb")
    assert fl.size > 3
    fl.each { |fn| assert_match /\.rb$/, fn }
  end

  def test_add_matching
    fl = FileList.new
    fl << "a.java"
    fl.add("test/*.rb")
    assert_equal "a.java", fl[0]
    assert fl.size > 2
    assert fl.include?("test/testfilelist.rb")
  end

  def test_multiple_patterns
    create_test_data
    fl = FileList.new
    fl.add('*.c', '*xist*')
    assert_equal [], fl
    fl.add('testdata/*.c', 'testdata/*xist*')
    assert_equal [
      'testdata/x.c', 'testdata/xyz.c', 'testdata/abc.c', 'testdata/existing'
    ].sort, fl.sort
  end

  def test_reject
    fl = FileList.new
    fl.add %w(testdata/x.c testdata/abc.c testdata/xyz.c testdata/existing)
    fl.reject! { |fn| fn =~ %r{/x} }
    assert_equal [
      'testdata/abc.c', 'testdata/existing'
    ], fl
  end

  def test_exclude
    fl = FileList['testdata/x.c', 'testdata/abc.c', 'testdata/xyz.c', 'testdata/existing']
    fl.exclude(%r{/x.+\.})
    assert_equal 4, fl.size
    fl.exclude!(%r{/x.+\.})
    assert_equal [
      'testdata/x.c', 'testdata/abc.c', 'testdata/existing'
    ], fl
  end

  def test_unique
    fl = FileList.new
    fl << "x.c" << "a.c" << "b.rb" << "a.c"
    assert_equal ['x.c', 'a.c', 'b.rb', 'a.c'], fl
    fl.uniq!
    assert_equal ['x.c', 'a.c', 'b.rb'], fl
  end

  def test_to_string
    fl = FileList.new
    fl << "a.java" << "b.java"
    assert_equal  "a.java b.java", fl.to_s
    assert_equal  "a.java b.java", "#{fl}"
  end

  def test_sub
    create_test_data
    fl = FileList["testdata/*.c"]
    f2 = fl.sub(/\.c$/, ".o")
    assert_equal FileList, f2.class
    assert_equal ["testdata/abc.o", "testdata/x.o", "testdata/xyz.o"].sort,
      f2.sort
  end

  def test_sub!
    create_test_data
    f = "x/a.c"
    fl = FileList[f, "x/b.c"]
    res = fl.sub!(/\.c$/, ".o")
    assert_equal ["x/a.o", "x/b.o"].sort, fl.sort
    assert_equal "x/a.c", f
    assert_equal f.id, res.id
  end

  def test_sub_with_block
    create_test_data
    fl = FileList["src/org/onestepback/a.java", "src/org/onestepback/b.java"]
# The block version doesn't work the way I want it to ...
#    f2 = fl.sub(%r{^src/(.*)\.java$}) { |x|  "classes/" + $1 + ".class" }
    f2 = fl.sub(%r{^src/(.*)\.java$}, "classes/\\1.class")
    assert_equal [
      "classes/org/onestepback/a.class",
      "classes/org/onestepback/b.class"
    ].sort,
      f2.sort
  end

  def test_gsub
    create_test_data
    fl = FileList["testdata/*.c"]
    f2 = fl.gsub(/a/, "A")
    assert_equal ["testdAtA/Abc.c", "testdAtA/x.c", "testdAtA/xyz.c"].sort,
      f2.sort
  end

  def create_test_data
    mkdir "testdata" unless File.exist? "testdata"
    touch "testdata/x.c", :verbose=>false
    touch "testdata/xyz.c", :verbose=>false
    touch "testdata/abc.c", :verbose=>false
    touch "testdata/existing", :verbose=>false
  end
  
end
