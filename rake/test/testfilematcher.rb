#!/usr/bin/env ruby

require 'test/unit'
require 'rake/filematcher'

class TestFileMatcher < Test::Unit::TestCase
  DIRPAT = 'test/test*.rb'
  @@test_files = Dir[DIRPAT]
  
  def setup
    @matcher = Rake::FileMatcher.new
  end

  def test_add_files
    @matcher << "a.x" << "b.y"
    assert_equal ["a.x", "b.y"], @matcher.files
  end

  def test_add_file_list
    @matcher << ['a', 'b']
    @matcher << 'x'
    assert_equal ['a', 'b', 'x'], @matcher.files
  end

  def test_match_files
    @matcher.add_matching(DIRPAT)
    assert @@test_files.sort, @matcher.files.sort
  end

  def test_each
    @matcher << "one" << "two"
    @matcher.add_matching(DIRPAT)
    assert_equal ["one", "two"] + @@test_files, @matcher.to_a
    assert_equal ["one", "two"], @matcher.select { |fn| fn.size == 3 }.sort
  end

  def test_patterns
    @matcher.glob(DIRPAT)
    assert_equal @@test_files.sort, @matcher.files.sort
    @matcher << "x"
    files = @matcher.to_a
    assert_equal "x", files[0]
    assert_equal((["x"] + @@test_files).sort, files.sort)
  end

  def test_multiple_patterns
    @matcher.glob('*er*', '*clean*')
    assert_equal [], @matcher.files
  end

  def test_anti_patterns
    @matcher << "erb"
    @matcher.glob(DIRPAT)
    @matcher.no_match('er.')
    assert @matcher.files.include?('test/testtask.rb')
    assert !@matcher.files.include?('test/testfilematcher.rb'),
      "should not contain testfilematcher.rb"
    assert @matcher.files.include?('erb'),
      "should contain erb"
  end

  def test_to_s
    @matcher << "x" << "y"
    assert_equal "x y", "#{@matcher}"
  end
end
