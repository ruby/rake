#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'
require 'rake'
require 'test/filecreation'

######################################################################
class TestTask < Test::Unit::TestCase
  def setup
    Task.clear
  end

  def test_create
    arg = nil
    t = Task.lookup(:name).enhance { |task| arg = task; 1234 }
    assert_equal "name", t.name
    assert [], t.prerequisites
    assert t.needed?
    t.execute
    assert_equal t, arg
    assert_nil t.source
  end

  def test_invoke
    runlist = []
    t1 = Task.lookup(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = Task.lookup(:t2).enhance { |t| runlist << t.name }
    t3 = Task.lookup(:t3).enhance { |t| runlist << t.name }
    assert_equal [:t2, :t3], t1.prerequisites
    t1.invoke
    assert_equal ["t2", "t3", "t1"], runlist
  end

  def test_no_double_invoke
    runlist = []
    t1 = Task.lookup(:t1).enhance([:t2, :t3]) { |t| runlist << t.name; 3321 }
    t2 = Task.lookup(:t2).enhance([:t3]) { |t| runlist << t.name }
    t3 = Task.lookup(:t3).enhance { |t| runlist << t.name }
    t1.invoke
    assert_equal ["t3", "t2", "t1"], runlist
  end

  def test_find
    task :tfind
    assert_equal "tfind", Task[:tfind].name
    ex = assert_raises(RuntimeError) { Task[:leaves] }
    assert_equal "Don't know how to rake leaves", ex.message
  end

  def test_defined
    assert ! Task.task_defined?(:a)
    task :a
    assert Task.task_defined?(:a)
  end

  def test_multi_invocations
    runs = []
    p = proc do |t| runs << t.name end
    task({:t1=>[:t2,:t3]}, &p)
    task({:t2=>[:t3]}, &p)
    task(:t3, &p)
    Task[:t1].invoke
    assert_equal ["t1", "t2", "t3"], runs.sort
  end

  def test_task_list
    task :t2
    task :t1 => [:t2]
    assert_equal ["t1", "t2"], Task.tasks.collect {|t| t.name}
  end

end

######################################################################
class TestFileTask < Test::Unit::TestCase
  include FileCreation

  def setup
    Task.clear
    @runs = Array.new
    FileUtils.rm_f NEWFILE
    FileUtils.rm_f OLDFILE
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

  OLDFILE = "testdata/old"
  NEWFILE = "testdata/new"

  def test_file_times_new_depends_on_old
    create_timed_files(OLDFILE, NEWFILE)

    t1 = FileTask.lookup(NEWFILE).enhance([OLDFILE])
    t2 = FileTask.lookup(OLDFILE)
    assert ! t2.needed?, "Should not need to build old file"
    assert ! t1.needed?, "Should not need to rebuild new file because of old"
  end

  def test_file_times_old_depends_on_new
    create_timed_files(OLDFILE, NEWFILE)

    t1 = FileTask.lookup(OLDFILE).enhance([NEWFILE])
    t2 = FileTask.lookup(NEWFILE)
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
  def setup
    rm_rf "testdata", :verbose=>false
  end

  def teardown
    rm_rf "testdata", :verbose=>false
  end

  def test_directory
    desc "DESC"
    directory "testdata/a/b/c"
    assert_equal FileTask, Task["testdata"].class
    assert_equal FileTask, Task["testdata/a"].class
    assert_equal FileTask, Task["testdata/a/b/c"].class
    assert_nil             Task["testdata"].comment
    assert_equal "DESC",   Task["testdata/a/b/c"].comment
    assert_nil             Task["testdata/a/b"].comment
    verbose(false) {
      Task['testdata/a/b'].invoke
    }
    assert File.exist?("testdata/a/b")
    assert ! File.exist?("testdata/a/b/c")
  end
end

__END__

######################################################################
class TestDefinitions < Test::Unit::TestCase
  EXISTINGFILE = "testdata/existing"

  def setup
    Task.clear
  end

  def test_task
    done = false
    task :one => [:two] do done = true end
    task :two
    task :three => [:one, :two]
    check_tasks(:one, :two, :three)
    assert done, "Should be done"
  end

  def test_file_task
    done = false
    file "testdata/one" => "testdata/two" do done = true end
    file "testdata/two"
    file "testdata/three" => ["testdata/one", "testdata/two"]
    check_tasks("testdata/one", "testdata/two", "testdata/three")
    assert done, "Should be done"
  end

  def check_tasks(n1, n2, n3)
    t = Task[n1]
    assert Task === t, "Should be a Task"
    assert_equal n1.to_s, t.name
    assert_equal [n2.to_s], t.prerequisites.collect{|n| n.to_s}
    t.invoke
    t2 = Task[n2]
    assert_equal [], t2.prerequisites
    t3 = Task[n3]
    assert_equal [n1.to_s, n2.to_s], t3.prerequisites.collect{|n|n.to_s}
  end

  def test_incremental_definitions
    runs = []
    task :t1 => [:t2] do runs << "A"; 4321 end
    task :t1 => [:t3] do runs << "B"; 1234 end
    task :t1 => [:t3]
    task :t2
    task :t3
    Task[:t1].invoke
    assert_equal ["A", "B"], runs
    assert_equal ["t2", "t3"], Task[:t1].prerequisites
  end

  def test_missing_dependencies
    task :x => ["testdata/missing"]
    assert_raises(RuntimeError) { Task[:x].invoke }
  end

  def test_implicit_file_dependencies
    runs = []
    create_existing_file
    task :y => [EXISTINGFILE] do |t| runs << t.name end
    Task[:y].invoke
    assert_equal runs, ['y']
  end

  private # ----------------------------------------------------------

  def create_existing_file
    if ! File.exist?(EXISTINGFILE)
      open(EXISTINGFILE, "w") do |f| f.puts "HI" end
    end
  end

end
  
######################################################################
class TestRules < Test::Unit::TestCase
  include FileCreation

  SRCFILE  = "testdata/abc.c"
  SRCFILE2 =  "testdata/xyz.c"
  FTNFILE  = "testdata/abc.f"
  OBJFILE  = "testdata/abc.o"

  def setup
    Task.clear
    @runs = []
  end

  def test_multiple_rules1
    create_file(FTNFILE)
    delete_file(SRCFILE)
    delete_file(OBJFILE)
    rule /\.o$/ => ['.c'] do @runs << :C end
    rule /\.o$/ => ['.f'] do @runs << :F end
    t = Task[OBJFILE]
    t.invoke
    Task[OBJFILE].invoke
    assert_equal [:F], @runs
  end

  def test_multiple_rules2
    create_file(FTNFILE)
    delete_file(SRCFILE)
    delete_file(OBJFILE)
    rule /\.o$/ => ['.f'] do @runs << :F end
    rule /\.o$/ => ['.c'] do @runs << :C end
    Task[OBJFILE].invoke
    assert_equal [:F], @runs
  end

  def test_create_with_source
    create_file(SRCFILE)
    rule /\.o$/ => ['.c'] do |t|
      @runs << t.name
      assert_equal OBJFILE, t.name
      assert_equal SRCFILE, t.source
    end
    Task[OBJFILE].invoke
    assert_equal [OBJFILE], @runs
  end

  def test_single_dependent
    create_file(SRCFILE)
    rule /\.o$/ => '.c' do |t|
      @runs << t.name
    end
    Task[OBJFILE].invoke
    assert_equal [OBJFILE], @runs
  end

  def test_create_by_string
    create_file(SRCFILE)
    rule '.o' => ['.c'] do |t|
      @runs << t.name
    end
    Task[OBJFILE].invoke
    assert_equal [OBJFILE], @runs
  end

  def test_rule_and_no_action_task
    create_file(SRCFILE)
    create_file(SRCFILE2)
    delete_file(OBJFILE)
    rule '.o' => '.c' do |t|
      @runs << t.source
    end
    file OBJFILE => [SRCFILE2]
    Task[OBJFILE].invoke
    assert_equal [SRCFILE], @runs
  end

  def test_string_close_matches
    create_file("testdata/x.c")
    rule '.o' => ['.c'] do |t|
      @runs << t.name
    end
    assert_raises(RuntimeError) { Task['testdata/x.obj'].invoke }
    assert_raises(RuntimeError) { Task['testdata/x.xyo'].invoke }
  end

  def test_precedence_rule_vs_implicit
    create_timed_files(OBJFILE, SRCFILE)
    rule /\.o$/ => ['.c'] do
      @runs << :RULE
    end
    Task[OBJFILE].invoke
    assert_equal [:RULE], @runs
  end

  def test_too_many_dependents
    assert_raises(RuntimeError) { rule '.o' => ['.c', '.cpp'] }
  end

  def test_proc_dependent
    ran = false
    File.makedirs("testdata/src/jw")
    create_file("testdata/src/jw/X.java")
    rule %r(classes/.*\.class) => [
      proc { |fn| fn.sub(/^classes/, 'testdata/src').sub(/\.class$/, '.java') }
    ] do |task|
      assert_equal task.name, 'classes/jw/X.class'
      assert_equal task.source, 'testdata/src/jw/X.java'
      ran = true
    end
    Task['classes/jw/X.class'].invoke
    assert ran, "Should have triggered rule"
  ensure
    rm_r("testdata/src", :verbose=>false) rescue nil
  end
end
