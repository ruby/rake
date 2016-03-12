require File.expand_path('../helper', __FILE__)
require 'rake/testtask'

class TestRakeTestTask < Rake::TestCase
  include Rake

  def test_initialize
    tt = Rake::TestTask.new do |t| end
    refute_nil tt
    assert_equal :test, tt.name
    assert_equal ['lib'], tt.libs
    assert_equal 'test/test*.rb', tt.pattern
    assert_equal false, tt.verbose
    assert_equal true, tt.warning
    assert_equal [], tt.deps
    assert Task.task_defined?(:test)
  end

  def test_initialize_override
    tt = Rake::TestTask.new(:example) do |t|
      t.description = "Run example tests"
      t.libs = ['src', 'ext']
      t.pattern = 'test/tc_*.rb'
      t.warning = true
      t.verbose = true
      t.deps = [:env]
    end
    refute_nil tt
    assert_equal "Run example tests", tt.description
    assert_equal :example, tt.name
    assert_equal ['src', 'ext'], tt.libs
    assert_equal 'test/tc_*.rb', tt.pattern
    assert_equal true, tt.warning
    assert_equal true, tt.verbose
    assert_equal [:env], tt.deps
    assert_match(/-w/, tt.ruby_opts_string)
    assert_match(/--verbose/, tt.ruby_opts_string)
    assert Task.task_defined?(:example)
  end

  def test_file_list_env_test
    ENV['TEST'] = 'testfile.rb'
    tt = Rake::TestTask.new do |t|
      t.pattern = '*'
    end

    assert_equal ["testfile.rb"], tt.file_list.to_a
  ensure
    ENV.delete 'TEST'
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

    assert_equal '', test_task.ruby_opts_string
  end

  def test_pattern_equals
    tt = Rake::TestTask.new do |t|
      t.pattern = '*.rb'
    end
    assert_equal ['*.rb'], tt.file_list.to_a
  end

  def test_pattern_equals_test_files_equals
    tt = Rake::TestTask.new do |t|
      t.test_files = FileList['a.rb', 'b.rb']
      t.pattern = '*.rb'
    end
    assert_equal ['a.rb', 'b.rb', '*.rb'], tt.file_list.to_a
  end

  def test_run_code_direct
    test_task = Rake::TestTask.new do |t|
      t.loader = :direct
    end

    assert_equal '-e "ARGV.each{|f| require f}"', test_task.run_code
  end

  def test_run_code_rake
    spec = Gem::Specification.new 'rake', 0
    spec.loaded_from = File.join Gem::Specification.dirs.last, 'rake-0.gemspec'
    rake, Gem.loaded_specs['rake'] = Gem.loaded_specs['rake'], spec

    test_task = Rake::TestTask.new do |t|
      t.loader = :rake
    end

    assert_match(/\A-I".*?" ".*?"\Z/, test_task.run_code)
  ensure
    Gem.loaded_specs['rake'] = rake
  end

  def test_run_code_rake_default_gem
    skip 'this ruby does not have default gems' unless
      Gem::Specification.method_defined? :default_specifications_dir

    default_spec = Gem::Specification.new 'rake', 0
    default_spec.loaded_from = File.join Gem::Specification.default_specifications_dir, 'rake-0.gemspec'
    begin
      rake, Gem.loaded_specs['rake'] = Gem.loaded_specs['rake'], default_spec

      test_task = Rake::TestTask.new do |t|
        t.loader = :rake
      end

      assert_match(/\A(-I".*?" *)* ".*?"\Z/, test_task.run_code)
    ensure
      Gem.loaded_specs['rake'] = rake
    end
  end

  def test_test_files_equals
    tt = Rake::TestTask.new do |t|
      t.test_files = FileList['a.rb', 'b.rb']
    end

    assert_equal ["a.rb", 'b.rb'], tt.file_list.to_a
  end

  def test_task_prerequisites
    Rake::TestTask.new :parent

    Rake::TestTask.new :child do |t|
      t.deps = :parent
    end

    task = Rake::Task[:child]
    assert_includes task.prerequisites, 'parent'
  end
end
