#!/usr/bin/env ruby

require 'test/unit'
require 'test/filecreation'
require 'fileutils'

class TestFileUtils < Test::Unit::TestCase
  include FileCreation

  def test_rm_one_file
    create_file("testdata/a")
    FileUtils.rm_r "testdata/a"
    assert ! File.exist?("testdata/a")
  end

  def test_rm_two_files
    create_file("testdata/a")
    create_file("testdata/b")
    FileUtils.rm_r ["testdata/a", "testdata/b"]
    assert ! File.exist?("testdata/a")
    assert ! File.exist?("testdata/b")
  end

  def test_rm_filelist
    list = Rake::FileList.new << "testdata/a" << "testdata/b"
    list.each { |fn| create_file(fn) }
    FileUtils.rm_r list
    assert ! File.exist?("testdata/a")
    assert ! File.exist?("testdata/b")
  end

  def test_verbose
    verbose true
    assert_equal true, verbose
    verbose false
    assert_equal false, verbose
    verbose(true){
      assert_equal true, verbose
    }
    assert_equal false, verbose
  end

  def test_nowrite
    nowrite true
    assert_equal true, nowrite
    nowrite false
    assert_equal false, nowrite
    nowrite(true){
      assert_equal true, nowrite
    }
    assert_equal false, nowrite
  end

end
