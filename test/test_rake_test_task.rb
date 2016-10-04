require File.expand_path("../helper", __FILE__)
require "rake/testtask"

class TestRakeTestTask < Rake::TestCase
  include Rake

  def test_initialize
    tt = Rake::TestTask.new do |t| end
    refute_nil tt
    assert_equal :test, tt.name
    assert_equal ["lib"], tt.libs
    assert_equal "test/test*.rb", tt.pattern
    assert_equal false, tt.verbose
    assert_equal true, tt.warning
    assert_equal [], tt.deps
    assert Task.task_defined?(:test)
  end

  def test_initialize_deps
    tt = Rake::TestTask.new(example: :bar)
    refute_nil tt
    assert_equal :bar, tt.deps
    assert Task.task_defined?(:example)
  end

  def test_initialize_multi_deps
    tt = Rake::TestTask.new(example: [:foo, :bar])
    refute_nil tt
    assert_equal [:foo, :bar], tt.deps
    assert Task.task_defined?(:example)
  end

  def test_initialize_override
    tt = Rake::TestTask.new(example: :bar) do |t|
      t.description = "Run example tests"
      t.libs = ["src", "ext"]
      t.pattern = "test/tc_*.rb"
      t.warning = true
      t.verbose = true
      t.deps = [:env]
    end
    refute_nil tt
    assert_equal "Run example tests", tt.description
    assert_equal :example, tt.name
    assert_equal ["src", "ext"], tt.libs
    assert_equal "test/tc_*.rb", tt.pattern
    assert_equal true, tt.warning
    assert_equal true, tt.verbose
    assert_equal [:env], tt.deps
    assert_match(/-w/, tt.ruby_opts_string)
    assert Task.task_defined?(:example)
  end

  def test_file_list_env_test
    ENV["TEST"] = "testfile.rb"
    tt = Rake::TestTask.new do |t|
      t.pattern = "*"
    end

    assert_equal ["testfile.rb"], tt.file_list.to_a
  ensure
    ENV.delete "TEST"
  end

  def test_libs_equals
    test_task = Rake::TestTask.new do |t|
      t.libs << ["A", "B"]
    end

    path = %w[lib A B].join File::PATH_SEPARATOR

    assert_equal "-w -I\"#{path}\"", test_task.ruby_opts_string
  end

  def test_libs_equals_empty
    test_task = Rake::TestTask.new do |t|
      t.libs    = []
      t.warning = false
    end

    assert_equal "", test_task.ruby_opts_string
  end

  def test_pattern_equals
    ['gl.rb', 'ob.rb'].each do |f|
      create_file(f)
    end
    tt = Rake::TestTask.new do |t|
      t.pattern = "*.rb"
    end
    assert_equal ["gl.rb", "ob.rb"], tt.file_list.to_a
  end

  def test_pattern_equals_test_files_equals
    ['gl.rb', 'ob.rb'].each do |f|
      create_file(f)
    end
    tt = Rake::TestTask.new do |t|
      t.test_files = FileList["a.rb", "b.rb"]
      t.pattern = "*.rb"
    end
    assert_equal ["a.rb", "b.rb", "gl.rb", "ob.rb"], tt.file_list.to_a
  end

  def test_run_code_direct
    globbed = ['test_gl.rb', 'test_ob.rb'].map { |f| File.join('test', f) }
    others = ['a.rb', 'b.rb'].map { |f| File.join('test', f) }
    (globbed + others).each do |f|
      create_file(f)
    end
    test_task = Rake::TestTask.new do |t|
      t.loader = :direct
      # if t.pettern and t.test_files are nil,
      # t.pettern is "test/test*.rb"
    end

    assert_equal '-e "ARGV.each{|f| require f}"', test_task.run_code
    assert_equal globbed, test_task.file_list.to_a
  end

  def test_run_code_rake
    spec = Gem::Specification.new "rake", 0
    spec.loaded_from = File.join Gem::Specification.dirs.last, "rake-0.gemspec"
    rake, Gem.loaded_specs["rake"] = Gem.loaded_specs["rake"], spec

    test_task = Rake::TestTask.new do |t|
      t.loader = :rake
    end

    assert_match(/\A-I".*?" ".*?"\Z/, test_task.run_code)
  ensure
    Gem.loaded_specs["rake"] = rake
  end

  def test_test_files_equals
    tt = Rake::TestTask.new do |t|
      t.test_files = FileList["a.rb", "b.rb"]
    end

    assert_equal ["a.rb", "b.rb"], tt.file_list.to_a
  end

  def test_task_prerequisites
    Rake::TestTask.new :parent
    Rake::TestTask.new child: :parent

    task = Rake::Task[:child]
    assert_includes task.prerequisites, "parent"
  end

  def test_task_prerequisites_multi
    Rake::TestTask.new :parent
    Rake::TestTask.new :parent2
    Rake::TestTask.new child: [:parent, :parent2]

    task = Rake::Task[:child]
    assert_includes task.prerequisites, "parent"
    assert_includes task.prerequisites, "parent2"
  end

  def test_task_prerequisites_deps
    Rake::TestTask.new :parent

    Rake::TestTask.new :child do |t|
      t.deps = :parent
    end

    task = Rake::Task[:child]
    assert_includes task.prerequisites, "parent"
  end
end
