#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'rake'
require 'test/file_creation'
require 'test/rake_test_setup'

######################################################################
class TestFileTask < Test::Unit::TestCase
  include Rake
  include FileCreation
  include TestMethods

  FILES = [ANCIENT_FILE, OLDFILE, MIDDLE_AGED_FILE, NEWFILE] 

  def setup
    Task.clear
    @runs = ThreadSafeArray.new
    FileUtils.rm_rf "testdata", :verbose => false
    FileUtils.mkdir_p "testdata", :verbose => false
  end

  def teardown
    FileUtils.rm_rf "testdata", :verbose => false
  end

  def test_create_dispersed_timed_files
    create_dispersed_timed_files(*FILES)
    assert_equal FILES, FILES.sort_by { |f| File.stat(f).mtime }
  end

  def test_file_need
    name = "testdata/dummy"
    file name
    ftask = Task[name]
    assert_equal name.to_s, ftask.name
    File.delete(ftask.name) rescue nil
    assert ftask.needed?, "file should be needed"
    open(ftask.name, "w") { |f| f.puts "HI" }
    assert_equal nil, ftask.prerequisites.collect{|n| Task[n].timestamp}.max
    assert ! ftask.needed?, "file should not be needed"
    File.delete(ftask.name) rescue nil
  end

  def test_file_times_new_depends_on_old
    create_timed_files(OLDFILE, NEWFILE)

    t1 = Rake.application.intern(FileTask, NEWFILE).enhance([OLDFILE])
    t2 = Rake.application.intern(FileTask, OLDFILE)
    assert ! t2.needed?, "Should not need to build old file"
    assert ! t1.needed?, "Should not need to rebuild new file because of old"
  end

  def test_file_times_old_depends_on_new
    create_timed_files(OLDFILE, NEWFILE)

    t1 = Rake.application.intern(FileTask,OLDFILE).enhance([NEWFILE])
    t2 = Rake.application.intern(FileTask, NEWFILE)
    assert ! t2.needed?, "Should not need to build new file"
    preq_stamp = t1.prerequisites.collect{|t| Task[t].timestamp}.max
    assert_equal t2.timestamp, preq_stamp
    assert t1.timestamp < preq_stamp, "T1 should be older"
    assert t1.needed?, "Should need to rebuild old file because of new"
  end

  def test_file_depends_on_task_depend_on_file
    create_timed_files(OLDFILE, NEWFILE)

    file NEWFILE => [:obj] do |t| @runs << t.name end
    task :obj => [OLDFILE] do |t| @runs << t.name end
    file OLDFILE           do |t| @runs << t.name end

    Task[:obj].invoke
    Task[NEWFILE].invoke
    assert ! @runs.include?(NEWFILE)
  end

  def test_existing_file_depends_on_non_existing_file
    create_file(OLDFILE)
    delete_file(NEWFILE)
    file NEWFILE
    file OLDFILE => NEWFILE
    assert_nothing_raised do Task[OLDFILE].invoke end
  end

  def test_old_file_in_between
    create_dispersed_timed_files(*FILES)

    file MIDDLE_AGED_FILE => OLDFILE do |t|
      @runs << t.name
      touch MIDDLE_AGED_FILE, :verbose => false
    end
    file OLDFILE => NEWFILE do |t|
      @runs << t.name
      touch OLDFILE, :verbose => false
    end
    file NEWFILE do |t|
      @runs << t.name
      touch NEWFILE, :verbose => false
    end

    Task[MIDDLE_AGED_FILE].invoke
    assert_equal([OLDFILE, MIDDLE_AGED_FILE], @runs)
  end

  def test_two_old_files_in_between
    create_dispersed_timed_files(*FILES)

    file MIDDLE_AGED_FILE => OLDFILE do |t|
      @runs << t.name
      touch MIDDLE_AGED_FILE, :verbose => false
    end
    file OLDFILE => ANCIENT_FILE do |t|
      @runs << t.name
      touch OLDFILE, :verbose => false
    end
    file ANCIENT_FILE => NEWFILE do |t|
      @runs << t.name
      touch ANCIENT_FILE, :verbose => false
    end
    file NEWFILE do |t|
      @runs << t.name
      touch NEWFILE, :verbose => false
    end

    Task[MIDDLE_AGED_FILE].invoke
    assert_equal([ANCIENT_FILE, OLDFILE, MIDDLE_AGED_FILE], @runs)
  end

  def test_old_file_in_between_with_missing_leaf
    create_dispersed_timed_files(MIDDLE_AGED_FILE, OLDFILE)
    sleep 1

    file MIDDLE_AGED_FILE => OLDFILE do |t|
      @runs << t.name
      touch MIDDLE_AGED_FILE, :verbose => false
    end
    file OLDFILE => NEWFILE do |t|
      @runs << t.name
      touch OLDFILE, :verbose => false
    end
    file NEWFILE do |t|
      @runs << t.name
      touch NEWFILE, :verbose => false
    end

    Task[MIDDLE_AGED_FILE].invoke
    assert_equal([NEWFILE, OLDFILE, MIDDLE_AGED_FILE], @runs)
  end

  def test_two_old_files_in_between_with_missing_leaf
    create_dispersed_timed_files(MIDDLE_AGED_FILE, OLDFILE, ANCIENT_FILE)
    sleep 1

    file MIDDLE_AGED_FILE => OLDFILE do |t|
      @runs << t.name
      touch MIDDLE_AGED_FILE, :verbose => false
    end
    file OLDFILE => ANCIENT_FILE do |t|
      @runs << t.name
      touch OLDFILE, :verbose => false
    end
    file ANCIENT_FILE => NEWFILE do |t|
      @runs << t.name
      touch ANCIENT_FILE, :verbose => false
    end
    file NEWFILE do |t|
      @runs << t.name
      touch NEWFILE, :verbose => false
    end

    Task[MIDDLE_AGED_FILE].invoke
    assert_equal([NEWFILE, ANCIENT_FILE, OLDFILE, MIDDLE_AGED_FILE], @runs)
  end

  def test_diamond_graph_with_missing_leaf
    a, b, c, d = %w[a b c d].map { |n| "testdata/#{n}" }
    create_timed_files(a, b, c)
    sleep 1
    
    file a => [b, c] do
      @runs << a
      touch a
    end
    file b => d do
      @runs << b
      touch b
    end
    file c => d do
      @runs << c
      touch c
    end
    file d do
      @runs << d
      touch d
    end

    Task[a].invoke
    assert_equal [a, b, c, d], @runs.sort
  end

  def test_diamond_graph_with_new_leaf
    a, b, c, d = %w[a b c d].map { |n| "testdata/#{n}" }
    create_timed_files(a, b, c)
    sleep 1
    touch d

    file a => [b, c] do
      @runs << a
      touch a
    end
    file b => d do
      @runs << b
      touch b
    end
    file c => d do
      @runs << c
      touch c
    end
    file d do
      @runs << d
      touch d
    end

    Task[a].invoke
    assert_equal [a, b, c], @runs.sort
  end

  def test_kite_graph_with_missing_leaf
    a, b, c, d, e = %w[a b c d e].map { |n| "testdata/#{n}" }
    create_timed_files(a, b, c, d)
    sleep 1

    file a => [b, c] do
      @runs << a
      touch a
    end
    file b => d do
      @runs << b
      touch b
    end
    file c => d do
      @runs << c
      touch c
    end
    file d => e do
      @runs << d
      touch d
    end
    file e do
      @runs << e
      touch e
    end

    Task[a].invoke
    assert_equal [a, b, c, d, e], @runs.sort
  end

  def test_kite_graph_with_new_leaf
    a, b, c, d, e = %w[a b c d e].map { |n| "testdata/#{n}" }
    create_timed_files(a, b, c, d)
    sleep 1
    touch e

    file a => [b, c] do
      @runs << a
      touch a
    end
    file b => d do
      @runs << b
      touch b
    end
    file c => d do
      @runs << c
      touch c
    end
    file d => e do
      @runs << d
      touch d
    end
    file e do
      @runs << e
      touch e
    end

    Task[a].invoke
    assert_equal [a, b, c, d], @runs.sort
  end

  # I have currently disabled this test.  I'm not convinced that
  # deleting the file target on failure is always the proper thing to
  # do.  I'm willing to hear input on this topic.
  def ztest_file_deletes_on_failure
    task :obj
    file NEWFILE => [:obj] do |t|
      FileUtils.touch NEWFILE
      fail "Ooops"
    end
    assert Task[NEWFILE]
    begin
      Task[NEWFILE].invoke
    rescue Exception
    end
    assert( ! File.exist?(NEWFILE), "NEWFILE should be deleted")
  end

end

######################################################################
class TestDirectoryTask < Test::Unit::TestCase
  include Rake

  def setup
    Rake.rm_rf "testdata", :verbose=>false
  end

  def teardown
    Rake.rm_rf "testdata", :verbose=>false
  end

  def test_directory
    desc "DESC"
    directory "testdata/a/b/c"
    assert_equal FileCreationTask, Task["testdata"].class
    assert_equal FileCreationTask, Task["testdata/a"].class
    assert_equal FileCreationTask, Task["testdata/a/b/c"].class
    assert_nil             Task["testdata"].comment
    assert_equal "DESC",   Task["testdata/a/b/c"].comment
    assert_nil             Task["testdata/a/b"].comment
    verbose(false) {
      Task['testdata/a/b'].invoke
    }
    assert File.exist?("testdata/a/b")
    assert ! File.exist?("testdata/a/b/c")
  end

  if Rake::Win32.windows?
    def test_directory_win32
      desc "WIN32 DESC"
      FileUtils.mkdir_p("testdata")
      Dir.chdir("testdata") do
        directory 'c:/testdata/a/b/c'
        assert_equal FileCreationTask, Task['c:/testdata'].class
        assert_equal FileCreationTask, Task['c:/testdata/a'].class
        assert_equal FileCreationTask, Task['c:/testdata/a/b/c'].class
        assert_nil             Task['c:/testdata'].comment
        assert_equal "WIN32 DESC",   Task['c:/testdata/a/b/c'].comment
        assert_nil             Task['c:/testdata/a/b'].comment
        verbose(false) {
          Task['c:/testdata/a/b'].invoke
        }
        assert File.exist?('c:/testdata/a/b')
        assert ! File.exist?('c:/testdata/a/b/c')
      end
    end
  end
end
