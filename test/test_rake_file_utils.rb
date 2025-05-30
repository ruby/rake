# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)
require "fileutils"

class TestRakeFileUtils < Rake::TestCase # :nodoc:
  def setup
    super
    @rake_test_sh = ENV["RAKE_TEST_SH"]
  end

  def teardown
    FileUtils::LN_SUPPORTED[0] = true
    RakeFileUtils.verbose_flag = Rake::FileUtilsExt::DEFAULT
    ENV["RAKE_TEST_SH"] = @rake_test_sh

    super
  end

  def test_rm_one_file
    create_file("a")
    FileUtils.rm_rf "a"
    refute File.exist?("a")
  end

  def test_rm_two_files
    create_file("a")
    create_file("b")
    FileUtils.rm_rf ["a", "b"]
    refute File.exist?("a")
    refute File.exist?("b")
  end

  def test_rm_filelist
    list = Rake::FileList.new << "a" << "b"
    list.each { |fn| create_file(fn) }
    FileUtils.rm_r list
    refute File.exist?("a")
    refute File.exist?("b")
  end

  def test_rm_nowrite
    create_file("a")
    nowrite(true) {
      rm_rf "a"
    }
    assert File.exist?("a")
    nowrite(false) {
      rm_rf "a", noop: true
    }
    assert File.exist?("a")
    nowrite(true) {
      rm_rf "a", noop: false
    }
    refute File.exist?("a")
  end

  def test_ln
    File.write("a", "TEST_LN\n")

    Rake::FileUtilsExt.safe_ln("a", "b", verbose: false)

    assert_equal "TEST_LN\n", File.read("b")
  end

  class BadLink # :nodoc:
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
    assert_equal ["a", "b"], c.cp_args
    c.safe_ln "x", "y"
    assert_equal ["x", "y"], c.cp_args
  end

  def test_safe_ln_failover_to_cp_on_not_implemented_error
    FileUtils::LN_SUPPORTED[0] = true
    c = BadLink.new(NotImplementedError)
    c.safe_ln "a", "b"
    assert_equal ["a", "b"], c.cp_args
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
    nowrite(true) {
      assert_equal true, nowrite
    }
    assert_equal false, nowrite
  end

  def test_file_utils_methods_are_available_at_top_level
    create_file("a")

    capture_output do
      rm_rf "a"
    end

    refute File.exist?("a")
  end

  def test_fileutils_methods_dont_leak
    obj = Object.new
    assert_raises(NoMethodError) { obj.copy } # from FileUtils
    assert_raises(NoMethodError) { obj.ruby "-v" } # from RubyFileUtils
  end

  def test_sh
    shellcommand

    verbose(false) { sh %{#{Rake::TestCase::RUBY} shellcommand.rb} }
    assert true, "should not fail"
  end

  def test_sh_with_a_single_string_argument
    check_expansion

    ENV["RAKE_TEST_SH"] = "someval"
    verbose(false) {
      sh %{#{RUBY} check_expansion.rb #{env_var} someval}
    }
  end

  def test_sh_with_env
    check_environment

    env = {
      "RAKE_TEST_SH" => "someval"
    }

    verbose(false) {
      sh env, RUBY, "check_environment.rb", "RAKE_TEST_SH", "someval"
    }
  end

  def test_sh_with_multiple_arguments
    omit if jruby9? # https://github.com/jruby/jruby/issues/3653

    check_no_expansion
    ENV["RAKE_TEST_SH"] = "someval"

    verbose(false) {
      sh RUBY, "check_no_expansion.rb", env_var, "someval"
    }
  end

  def test_sh_with_spawn_options
    omit "JRuby does not support spawn options" if jruby?

    echocommand

    r, w = IO.pipe

    verbose(false) {
      sh RUBY, "echocommand.rb", out: w
    }

    w.close

    assert_equal "echocommand.rb\n", r.read
  end

  def test_sh_with_hash_option
    omit "JRuby does not support spawn options" if jruby?
    check_expansion

    verbose(false) {
      sh "#{RUBY} check_expansion.rb", { chdir: "." }, verbose: false
    }
  end

  def test_sh_failure
    shellcommand

    assert_raises(RuntimeError) {
      verbose(false) { sh %{#{RUBY} shellcommand.rb 1} }
    }
  end

  def test_sh_special_handling
    shellcommand

    count = 0
    verbose(false) {
      sh(%{#{RUBY} shellcommand.rb}) do |ok, res|
        assert(ok)
        assert_equal 0, res.exitstatus
        count += 1
      end
      sh(%{#{RUBY} shellcommand.rb 1}) do |ok, res|
        assert(!ok)
        assert_equal 1, res.exitstatus
        count += 1
      end
    }
    assert_equal 2, count, "Block count should be 2"
  end

  def test_sh_noop
    shellcommand

    verbose(false) { sh %{shellcommand.rb 1}, noop: true }
    assert true, "should not fail"
  end

  def test_sh_bad_option
    # Skip on JRuby because option checking is performed by spawn via system
    # now.
    omit "JRuby does not support spawn options" if jruby?

    shellcommand

    ex = assert_raises(ArgumentError) {
      verbose(false) { sh %{shellcommand.rb}, bad_option: true }
    }
    assert_match(/bad_option/, ex.message)
  end

  def test_sh_verbose
    shellcommand

    _, err = capture_output do
      verbose(true) {
        sh %{shellcommand.rb}, noop: true
      }
    end

    assert_equal "shellcommand.rb\n", err
  end

  def test_sh_verbose_false
    shellcommand

    _, err = capture_output do
      verbose(false) {
        sh %{shellcommand.rb}, noop: true
      }
    end

    assert_equal "", err
  end

  def test_sh_verbose_flag_nil
    shellcommand

    RakeFileUtils.verbose_flag = nil

    out, _ = capture_output do
      sh %{shellcommand.rb}, noop: true
    end
    assert_empty out
  end

  def test_ruby_with_a_single_string_argument
    check_expansion

    ENV["RAKE_TEST_SH"] = "someval"

    verbose(false) {
      replace_ruby {
        ruby %{check_expansion.rb #{env_var} someval}
      }
    }
  end

  def test_sh_show_command
    env = {
      "RAKE_TEST_SH" => "someval"
    }

    cmd = [env, RUBY, "some_file.rb", "some argument"]

    show_cmd = send :sh_show_command, cmd

    expected_cmd = "RAKE_TEST_SH=someval #{RUBY} some_file.rb some argument"

    assert_equal expected_cmd, show_cmd
  end

  def test_sh_if_a_command_exits_with_error_status_its_full_output_is_printed
    verbose false do
      standard_output = "Some output"
      standard_error  = "Some error"
      shell_command = "ruby -e\"puts '#{standard_output}';STDERR.puts '#{standard_error}';exit false\""
      actual_both = capture_subprocess_io do
        begin
          sh shell_command
        rescue
        else
          flunk
        end
      end
      actual = actual_both.join
      assert_match standard_output, actual
      assert_match standard_error,  actual
    end
  end

  def test_sh_if_a_command_exits_with_error_status_sh_echoes_it_fully
    verbose true do
      assert_echoes_fully
    end
    verbose false do
      assert_echoes_fully
    end
  end

  # Originally copied from minitest/assertions.rb
  def capture_subprocess_io
    begin
      require "tempfile"

      captured_stdout = Tempfile.new("out")
      captured_stderr = Tempfile.new("err")

      orig_stdout = $stdout.dup
      orig_stderr = $stderr.dup
      $stdout.reopen captured_stdout
      $stderr.reopen captured_stderr

      yield

      $stdout.rewind
      $stderr.rewind

      [captured_stdout.read, captured_stderr.read]
    ensure
      $stdout.reopen orig_stdout
      $stderr.reopen orig_stderr

      orig_stdout.close
      orig_stderr.close
      captured_stdout.close!
      captured_stderr.close!
    end
  end

  def assert_echoes_fully
    long_string = "1234567890" * 10
    shell_command = "ruby -e\"'#{long_string}';exit false\""
    capture_subprocess_io do
      begin
        sh shell_command
      rescue => ex
        assert_match "Command failed with status", ex.message
        assert_match shell_command, ex.message
      else
        flunk
      end
    end
  end

  def test_ruby_with_multiple_arguments
    omit if jruby9? # https://github.com/jruby/jruby/issues/3653

    check_no_expansion

    ENV["RAKE_TEST_SH"] = "someval"
    verbose(false) {
      replace_ruby {
        ruby "check_no_expansion.rb", env_var, "someval"
      }
    }
  end

  def test_split_all
    assert_equal ["a"], Rake::FileUtilsExt.split_all("a")
    assert_equal [".."], Rake::FileUtilsExt.split_all("..")
    assert_equal ["/"], Rake::FileUtilsExt.split_all("/")
    assert_equal ["a", "b"], Rake::FileUtilsExt.split_all("a/b")
    assert_equal ["/", "a", "b"], Rake::FileUtilsExt.split_all("/a/b")
    assert_equal ["..", "a", "b"], Rake::FileUtilsExt.split_all("../a/b")
  end

  def command(name, text)
    File.write(name, text)
  end

  def check_no_expansion
    command "check_no_expansion.rb", <<~CHECK_EXPANSION
      if ARGV[0] != ARGV[1]
        exit 0
      else
        exit 1
      end
    CHECK_EXPANSION
  end

  def check_environment
    command "check_environment.rb", <<~CHECK_ENVIRONMENT
      if ENV[ARGV[0]] != ARGV[1]
        exit 1
      else
        exit 0
      end
    CHECK_ENVIRONMENT
  end

  def check_expansion
    command "check_expansion.rb", <<~CHECK_EXPANSION
      if ARGV[0] != ARGV[1]
        exit 1
      else
        exit 0
      end
    CHECK_EXPANSION
  end

  def echocommand
    command "echocommand.rb", <<~ECHOCOMMAND
      #!/usr/bin/env ruby

      puts "echocommand.rb"

      exit 0
    ECHOCOMMAND
  end

  def replace_ruby
    ruby = FileUtils::RUBY
    FileUtils.send :remove_const, :RUBY
    FileUtils.const_set :RUBY, RUBY
    yield
  ensure
    FileUtils.send :remove_const, :RUBY
    FileUtils.const_set:RUBY, ruby
  end

  def shellcommand
    command "shellcommand.rb", <<~SHELLCOMMAND
      #!/usr/bin/env ruby

      exit((ARGV[0] || "0").to_i)
    SHELLCOMMAND
  end

  def env_var
    windows? ? "%RAKE_TEST_SH%" : "$RAKE_TEST_SH"
  end

  def windows?
    ! File::ALT_SEPARATOR.nil?
  end

end
