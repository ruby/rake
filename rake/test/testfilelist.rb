#!/usr/bin/env ruby

require 'test/unit'
require 'rake'

class TestFileList < Test::Unit::TestCase
  FileList = Rake::FileList

  def setup
    create_test_data
  end

  def teardown
    FileList.select_default_ignore_patterns
  end

  def test_create
    fl = FileList.new
    assert_equal 0, fl.size
  end

  def test_create_with_args
    fl = FileList.new("testdata/*.c", "x")
    assert_equal ["testdata/abc.c", "testdata/x.c", "testdata/xyz.c", "x"].sort,
      fl.sort
  end

  def test_create_with_block
    fl = FileList.new { |f| f.include("x") }
    assert_equal ["x"], fl.resolve
  end

  def test_create_with_brackets
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
    fl.include %w(a d c )
    fl.include('x', 'y')
    assert_equal ['a', 'd', 'c', 'x', 'y'], fl.resolve
  end

  def test_add_return
    f = FileList.new
    g = f << "x"
    assert_equal f.id, g.id
    h = f.include("y")
    assert_equal f.id, h.id
  end
  
  def test_match
    fl = FileList.new
    fl.include('test/test*.rb')
    assert fl.include?("test/testfilelist.rb")
    assert fl.size > 3
    fl.each { |fn| assert_match /\.rb$/, fn }
  end

  def test_add_matching
    fl = FileList.new
    fl << "a.java"
    fl.include("test/*.rb")
    assert_equal "a.java", fl[0]
    assert fl.size > 2
    assert fl.include?("test/testfilelist.rb")
  end

  def test_multiple_patterns
    create_test_data
    fl = FileList.new
    fl.include('*.c', '*xist*')
    assert_equal [], fl
    fl.include('testdata/*.c', 'testdata/*xist*')
    assert_equal [
      'testdata/x.c', 'testdata/xyz.c', 'testdata/abc.c', 'testdata/existing'
    ].sort, fl.sort
  end

  def test_reject
    fl = FileList.new
    fl.include %w(testdata/x.c testdata/abc.c testdata/xyz.c testdata/existing)
    fl.reject! { |fn| fn =~ %r{/x} }
    assert_equal [
      'testdata/abc.c', 'testdata/existing'
    ], fl
  end

  def test_exclude
    fl = FileList['testdata/x.c', 'testdata/abc.c', 'testdata/xyz.c', 'testdata/existing']
    fl.each { |fn| touch fn, :verbose => false }
    x = fl.exclude(%r{/x.+\.})
    assert_equal [
      'testdata/x.c', 'testdata/abc.c', 'testdata/existing'
    ], fl
    assert_equal fl.id, x.id
    fl.exclude('testdata/*.c')
    assert_equal ['testdata/existing'], fl
    fl.exclude('testdata/existing')
    assert_equal [], fl
  end

  def test_default_exclude
    fl = FileList.new
    fl.clear_exclude
    fl.include("**/*~", "**/*.bak", "**/core")
    assert fl.member?("testdata/core"), "Should include core"
    assert fl.member?("testdata/x.bak"), "Should include .bak files"
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
    fl = FileList["testdata/*.c"]
    f2 = fl.sub(/\.c$/, ".o")
    assert_equal FileList, f2.class
    assert_equal ["testdata/abc.o", "testdata/x.o", "testdata/xyz.o"].sort,
      f2.sort
    f3 = fl.gsub(/\.c$/, ".o")
    assert_equal FileList, f3.class
    assert_equal ["testdata/abc.o", "testdata/x.o", "testdata/xyz.o"].sort,
      f3.sort
  end

  def test_sub!
    f = "x/a.c"
    fl = FileList[f, "x/b.c"]
    res = fl.sub!(/\.c$/, ".o")
    assert_equal ["x/a.o", "x/b.o"].sort, fl.sort
    assert_equal "x/a.c", f
    assert_equal fl.id, res.id
  end

  def test_sub_with_block
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

  def test_ignore_special
    f = FileList['testdata/*']
    assert ! f.include?("testdata/CVS"), "Should not contain CVS"
    assert ! f.include?("testdata/.dummy"), "Should not contain dot files"
    assert ! f.include?("testdata/x.bak"), "Should not contain .bak files"
    assert ! f.include?("testdata/x~"), "Should not contain ~ files"
    assert ! f.include?("testdata/core"), "Should not contain core files"
  end

  def test_clear_ignore_patterns
    f = FileList['testdata/*']
    f.clear_exclude
    assert f.include?("testdata/abc.c")
    assert f.include?("testdata/xyz.c")
    assert f.include?("testdata/CVS")
    assert f.include?("testdata/x.bak")
    assert f.include?("testdata/x~")
  end

  def test_exclude_with_alternate_file_seps
    fl = FileList.new
    assert fl.exclude?("x/CVS/y")
    assert fl.exclude?("x\\CVS\\y")
    assert fl.exclude?("x/core")
    assert fl.exclude?("x\\core")
  end

  def test_add_default_exclude_list
    fl = FileList.new
    fl.exclude(/~\d+$/)
    assert fl.exclude?("x/CVS/y")
    assert fl.exclude?("x\\CVS\\y")
    assert fl.exclude?("x/core")
    assert fl.exclude?("x\\core")
    assert fl.exclude?("x/abc~1")
  end

  def test_basic_array_functions
    f = FileList['b', 'c', 'a']
    assert_equal 'b', f.first
    assert_equal 'b', f[0]
    assert_equal 'a', f.last
    assert_equal 'a', f[2]
    assert_equal 'a', f[-1]
    assert_equal ['a', 'b', 'c'], f.sort
    f.sort!
    assert_equal ['a', 'b', 'c'], f
  end

  def create_test_data
    verbose(false) do
      mkdir "testdata" unless File.exist? "testdata"
      mkdir "testdata/CVS" rescue nil
      touch "testdata/.dummy"
      touch "testdata/x.bak"
      touch "testdata/x~"
      touch "testdata/core"
      touch "testdata/x.c"
      touch "testdata/xyz.c"
      touch "testdata/abc.c"
      touch "testdata/existing"
    end
  end
  
end
