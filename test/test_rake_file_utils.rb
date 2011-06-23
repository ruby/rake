require File.expand_path('../helper', __FILE__)
require 'fileutils'
require 'stringio'

class TestRakeFileUtils < Rake::TestCase

  def setup
    super

    Dir.chdir @tempdir
  end

  def teardown
    FileUtils.rm_rf("testdata")
    FileUtils::LN_SUPPORTED[0] = true

    super
  end

  def test_rm_one_file
    create_file("testdata/a")
    FileUtils.rm_rf "testdata/a"
    assert ! File.exist?("testdata/a")
  end

  def test_rm_two_files
    create_file("testdata/a")
    create_file("testdata/b")
    FileUtils.rm_rf ["testdata/a", "testdata/b"]
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

  def test_ln
    create_dir("testdata")
    open("testdata/a", "w") { |f| f.puts "TEST_LN" }
    Rake::FileUtilsExt.safe_ln("testdata/a", "testdata/b", :verbose => false)
    assert_equal "TEST_LN\n", open("testdata/b") { |f| f.read }
  end

  class BadLink
    include Rake::FileUtilsExt
    attr_reader :cp_args
    def initialize(klass)
      @failure_class = klass
    end
    def cp(*args)
      @cp_args = args
    end
    def ln(*args)
      fail @failure_class, "ln not supported"
    end
    public :safe_ln
  end

  def test_safe_ln_failover_to_cp_on_standard_error
    FileUtils::LN_SUPPORTED[0] = true
    c = BadLink.new(StandardError)
    c.safe_ln "a", "b"
    assert_equal ['a', 'b'], c.cp_args
    c.safe_ln "x", "y"
    assert_equal ['x', 'y'], c.cp_args
  end

  def test_safe_ln_failover_to_cp_on_not_implemented_error
    FileUtils::LN_SUPPORTED[0] = true
    c = BadLink.new(NotImplementedError)
    c.safe_ln "a", "b"
    assert_equal ['a', 'b'], c.cp_args
  end

  def test_safe_ln_fails_on_script_error
    FileUtils::LN_SUPPORTED[0] = true
    c = BadLink.new(ScriptError)
    assert_raises(ScriptError) do c.safe_ln "a", "b" end
  end

  def test_verbose
    verbose true
    assert_equal true, verbose
    verbose false
    assert_equal false, verbose
    verbose(true) {
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

  def test_file_utils_methods_are_available_at_top_level
    create_file("testdata/a")
    rm_rf "testdata/a"
    assert ! File.exist?("testdata/a")
  end

  def test_fileutils_methods_dont_leak
    obj = Object.new
    assert_raises(NoMethodError) { obj.copy } # from FileUtils
    assert_raises(NoMethodError) { obj.ruby "-v" } # from RubyFileUtils
  end

  def test_sh
    shellcommand

    verbose(false) { sh %{#{FileUtils::RUBY} shellcommand.rb} }
    assert true, "should not fail"
  end

  # If the :sh method is invoked directly from a test unit instance
  # (under mini/test), the mini/test version of fail is invoked rather
  # than the kernel version of fail. So we run :sh from within a
  # non-test class to avoid the problem.
  class Sh
    include FileUtils
    def run(*args)
      sh(*args)
    end
    def self.run(*args)
      new.run(*args)
    end
    def self.ruby(*args)
      Sh.run(RUBY, *args)
    end
  end

  def test_sh_with_a_single_string_argument
    check_expansion

    ENV['RAKE_TEST_SH'] = 'someval'
    verbose(false) {
      sh %{#{FileUtils::RUBY} check_expansion.rb #{env_var} someval}
    }
  end

  def test_sh_with_multiple_arguments
    check_no_expansion
    ENV['RAKE_TEST_SH'] = 'someval'

    verbose(false) {
      Sh.ruby 'check_no_expansion.rb', env_var, 'someval'
    }
  end

  def test_sh_failure
    shellcommand

    assert_raises(RuntimeError) {
      verbose(false) { Sh.run %{#{FileUtils::RUBY} shellcommand.rb 1} }
    }
  end

  def test_sh_special_handling
    shellcommand

    count = 0
    verbose(false) {
      sh(%{#{FileUtils::RUBY} shellcommand.rb}) do |ok, res|
        assert(ok)
        assert_equal 0, res.exitstatus
        count += 1
      end
      sh(%{#{FileUtils::RUBY} shellcommand.rb 1}) do |ok, res|
        assert(!ok)
        assert_equal 1, res.exitstatus
        count += 1
      end
    }
    assert_equal 2, count, "Block count should be 2"
  end

  def test_sh_noop
    shellcommand

    verbose(false) { sh %{shellcommand.rb 1}, :noop=>true }
    assert true, "should not fail"
  end

  def test_sh_bad_option
    shellcommand

    ex = assert_raises(ArgumentError) {
      verbose(false) { sh %{shellcommand.rb}, :bad_option=>true }
    }
    assert_match(/bad_option/, ex.message)
  end

  def test_sh_verbose
    shellcommand

    _, err = capture_io do
      verbose(true) {
        sh %{shellcommand.rb}, :noop=>true
      }
    end

    assert_equal "shellcommand.rb\n", err
  end

  def test_sh_no_verbose
    shellcommand

    _, err = capture_io do
      verbose(false) {
        sh %{shellcommand.rb}, :noop=>true
      }
    end

    assert_equal '', err
  end

  def test_ruby_with_a_single_string_argument
    check_expansion

    ENV['RAKE_TEST_SH'] = 'someval'

    verbose(false) {
      ruby %{check_expansion.rb #{env_var} someval}
    }
  end

  def test_ruby_with_multiple_arguments
    check_no_expansion

    ENV['RAKE_TEST_SH'] = 'someval'
    verbose(false) {
      ruby 'check_no_expansion.rb', env_var, 'someval'
    }
  end

  def test_split_all
    assert_equal ['a'], Rake::FileUtilsExt.split_all('a')
    assert_equal ['..'], Rake::FileUtilsExt.split_all('..')
    assert_equal ['/'], Rake::FileUtilsExt.split_all('/')
    assert_equal ['a', 'b'], Rake::FileUtilsExt.split_all('a/b')
    assert_equal ['/', 'a', 'b'], Rake::FileUtilsExt.split_all('/a/b')
    assert_equal ['..', 'a', 'b'], Rake::FileUtilsExt.split_all('../a/b')
  end

  def command name, text
    open name, 'w', 0750 do |io|
      io << text
    end
  end

  def check_no_expansion
    command 'check_no_expansion.rb', <<-CHECK_EXPANSION
if ARGV[0] != ARGV[1]
  exit 0
else
  exit 1
end
    CHECK_EXPANSION
  end

  def check_expansion
    command 'check_expansion.rb', <<-CHECK_EXPANSION
if ARGV[0] != ARGV[1]
  exit 1
else
  exit 0
end
    CHECK_EXPANSION
  end

  def shellcommand
    command 'shellcommand.rb', <<-SHELLCOMMAND
#!/usr/bin/env ruby

exit((ARGV[0] || "0").to_i)
    SHELLCOMMAND
  end

  def env_var
    windows? ? '%RAKE_TEST_SH%' : '$RAKE_TEST_SH'
  end

  def windows?
    ! File::ALT_SEPARATOR.nil?
  end

end
