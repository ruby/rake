#!/usr/bin/env ruby

require 'test/unit'
require 'test/filecreation'

class TestSys < Test::Unit::TestCase
  include FileCreation

  def test_delete
    create_file("testdata/a")
    Sys.delete_all("testdata/a")
    assert ! File.exist?("testdata/a")
  end

  def test_copy
    create_file("testdata/a")
    Sys.copy("testdata/a", "testdata/b")
    assert File.exist?("testdata/b")
  end

  def test_for_files
    test_files = ["testdata/a.pl", "testdata/c.pl", "testdata/b.rb"]
    test_files.each { |fn| create_file(fn) }
    list = []
    Sys.for_files("testdata/*.pl", "testdata/*.rb") { |fn|
      list << fn
    }
    assert_equal test_files.sort, list.sort
  end

  def test_indir
    here = Dir.pwd
    Sys.makedirs("testdata/dir")
    assert_equal "#{here}/testdata/dir", Sys.indir("testdata/dir") { Dir.pwd }
    assert_equal here, Dir.pwd
  end
end
