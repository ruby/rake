#!/usr/bin/env ruby

require 'test/unit'
require 'rake/filelist'

class TestFileList < Test::Unit::TestCase
  def test_create
    fl = Rake::FileList.new
    assert_not_nil fl
  end

  def test_match
    fl = Rake::FileList.new('test/*.rb')
    assert fl.include?("test/testfilelist.rb")
    assert fl.size > 3
    fl.each { |fn| assert_match /\.rb$/, fn }
  end

  def test_to_string
    fl = Rake::FileList.new
    fl << "a.java" << "b.java"
    assert_equal  "a.java b.java", fl.to_s
    assert_equal  "a.java b.java", "#{fl}"
  end

  def test_add_matching
    fl = Rake::FileList.new
    fl << "a.java"
    fl.add_matching("test/*.rb")
    assert_equal "a.java", fl[0]
    assert fl.size > 2
    assert fl.include?("test/testfilelist.rb")
  end
end
