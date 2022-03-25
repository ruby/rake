# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeApplication < Rake::TestCase # :nodoc:

  def setup
    super

    @app = Rake.application
    @app.options.rakelib = []
  end

  def test_class_with_application
    orig_app = Rake.application

    return_app = Rake.with_application do |yield_app|
      refute_equal orig_app, yield_app, "new application must be yielded"

      assert_equal yield_app, Rake.application,
                   "new application must be default in block"
    end

    refute_equal orig_app, return_app, "new application not returned"
    assert_equal orig_app, Rake.application, "original application not default"
  end

  def test_class_with_application_user_defined
    orig_app = Rake.application

    user_app = Rake::Application.new

    return_app = Rake.with_application user_app do |yield_app|
      assert_equal user_app, yield_app, "user application must be yielded"

      assert_equal user_app, Rake.application,
                   "user application must be default in block"
    end

    assert_equal user_app, return_app, "user application not returned"
    assert_equal orig_app, Rake.application, "original application not default"
  end

  def test_display_exception_details
    obj = Object.new
    obj.instance_eval("def #{__method__}; raise 'test'; end", "ruby")
    begin
      obj.__send__(__method__)
    rescue => ex
    end

    out, err = capture_io do
      @app.set_default_options # reset trace output IO

      @app.display_error_message ex
    end

    assert_empty out

    assert_match "rake aborted!", err
    assert_match __method__.to_s, err
  end

  def test_display_exception_details_bad_encoding
    begin
      raise "El Niño is coming!".dup.force_encoding("US-ASCII")
    rescue => ex
    end

    out, err = capture_io do
      @app.set_default_options # reset trace output IO

      @app.display_error_message ex
    end

    assert_empty out
    assert_match "El Niño is coming!", err.force_encoding("UTF-8")
  end

  def test_display_exception_details_cause
    begin
      raise "cause a"
    rescue
      begin
        raise "cause b"
      rescue => ex
      end
    end

    out, err = capture_io do
      @app.set_default_options # reset trace output IO

      @app.display_error_message ex
    end

    assert_empty out

    assert_match "Caused by:", err
    assert_match "cause a", err
    assert_match "cause b", err
  end

  def test_display_tasks
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    @app.last_description = "COMMENT"
    @app.define_task(Rake::Task, "t")
    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
    assert_match(/^rake t/, out)
    assert_match(/# COMMENT/, out)
  end

  def test_display_tasks_with_long_comments
    @app.terminal_columns = 80
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    numbers = "1234567890" * 8
    @app.last_description = numbers
    @app.define_task(Rake::Task, "t")

    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end

    assert_match(/^rake t/, out)
    assert_match(/# #{numbers[0, 65]}\.\.\./, out)
  end

  def test_display_tasks_with_task_name_wider_than_tty_display
    @app.terminal_columns = 80
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    task_name = "task name" * 80
    @app.last_description = "something short"
    @app.define_task(Rake::Task, task_name)

    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end

    # Ensure the entire task name is output and we end up showing no description
    assert_match(/rake #{task_name}  # .../, out)
  end

  def test_display_tasks_with_very_long_task_name_to_a_non_tty_shows_name_and_comment
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    @app.tty_output = false
    description = "something short"
    task_name = "task name" * 80
    @app.last_description = "something short"
    @app.define_task(Rake::Task, task_name)

    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end

    # Ensure the entire task name is output and we end up showing no description
    assert_match(/rake #{task_name}  # #{description}/, out)
  end

  def test_display_tasks_with_long_comments_to_a_non_tty_shows_entire_comment
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    @app.tty_output = false
    @app.last_description = "1234567890" * 8
    @app.define_task(Rake::Task, "t")
    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
    assert_match(/^rake t/, out)
    assert_match(/# #{@app.last_description}/, out)
  end

  def test_truncating_comments_to_a_non_tty
    @app.terminal_columns = 80
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    @app.tty_output = false
    numbers = "1234567890" * 8
    @app.last_description = numbers
    @app.define_task(Rake::Task, "t")

    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end

    assert_match(/^rake t/, out)
    assert_match(/# #{numbers[0, 65]}\.\.\./, out)
  end

  def test_describe_tasks
    @app.options.show_tasks = :describe
    @app.options.show_task_pattern = //
    @app.last_description = "COMMENT"
    @app.define_task(Rake::Task, "t")
    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
    assert_match(/^rake t$/, out)
    assert_match(/^ {4}COMMENT$/, out)
  end

  def test_show_lines
    @app.options.show_tasks = :lines
    @app.options.show_task_pattern = //
    @app.last_description = "COMMENT"
    @app.define_task(Rake::Task, "t")
    @app["t"].locations << "HERE:1"
    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
    assert_match(/^rake t +[^:]+:\d+ *$/, out)
  end

  def test_finding_rakefile
    rakefile_default

    assert_match(/Rakefile/i, @app.instance_eval { have_rakefile })
  end

  def test_not_finding_rakefile
    @app.instance_eval { @rakefiles = ["NEVER_FOUND"] }
    assert(! @app.instance_eval do have_rakefile end)
    assert_nil @app.rakefile
  end

  def test_load_rakefile
    rakefile_unittest

    @app.instance_eval do
      handle_options []
      options.silent = true
      load_rakefile
    end

    assert_equal "rakefile", @app.rakefile.downcase
    assert_equal @tempdir, Dir.pwd
  end

  def test_load_rakefile_doesnt_print_rakefile_directory_from_same_dir
    rakefile_unittest

    _, err = capture_io do
      @app.instance_eval do
        # pretend we started from the unittest dir
        @original_dir = File.expand_path(".")
        raw_load_rakefile
      end
    end

    assert_empty err
  end

  def test_load_rakefile_from_subdir
    rakefile_unittest
    Dir.chdir "subdir"
    @app = Rake::Application.new

    @app.instance_eval do
      handle_options []
      options.silent = true
      load_rakefile
    end

    assert_equal "rakefile", @app.rakefile.downcase
    assert_equal @tempdir, Dir.pwd
  end

  def test_load_rakefile_prints_rakefile_directory_from_subdir
    rakefile_unittest
    Dir.chdir "subdir"

    app = Rake::Application.new
    app.options.rakelib = []

    _, err = capture_io do
      app.instance_eval do
        raw_load_rakefile
      end
    end

    assert_equal "(in #{@tempdir}\)\n", err
  end

  def test_load_rakefile_doesnt_print_rakefile_directory_from_subdir_if_silent
    rakefile_unittest
    Dir.chdir "subdir"

    _, err = capture_io do
      @app.instance_eval do
        handle_options []
        options.silent = true
        raw_load_rakefile
      end
    end

    assert_empty err
  end

  def test_load_rakefile_not_found
    skip if jruby9?

    Dir.chdir @tempdir
    ENV["RAKE_SYSTEM"] = "not_exist"

    @app.instance_eval do
      handle_options []
      options.silent = true
    end

    ex = assert_raises(RuntimeError) do
      @app.instance_eval do
        raw_load_rakefile
      end
    end

    assert_match(/no rakefile found/i, ex.message)
  end

  def test_load_from_system_rakefile
    rake_system_dir

    @app.instance_eval do
      handle_options []
      options.silent = true
      options.load_system = true
      options.rakelib = []
      load_rakefile
    end

    assert_equal @system_dir, @app.system_dir
    assert_nil @app.rakefile
  rescue SystemExit
    flunk "failed to load rakefile"
  end

  def test_load_from_calculated_system_rakefile
    rakefile_default
    def @app.standard_system_dir
      "__STD_SYS_DIR__"
    end

    ENV["RAKE_SYSTEM"] = nil

    @app.instance_eval do
      handle_options []
      options.silent = true
      options.load_system = true
      options.rakelib = []
      load_rakefile
    end

    assert_equal "__STD_SYS_DIR__", @app.system_dir
  rescue SystemExit
    flunk "failed to find system rakefile"
  end

  def test_terminal_columns
    old_rake_columns = ENV["RAKE_COLUMNS"]

    ENV["RAKE_COLUMNS"] = "42"

    app = Rake::Application.new

    assert_equal 42, app.terminal_columns
  ensure
    if old_rake_columns
      ENV["RAKE_COLUMNS"] = old_rake_columns
    else
      ENV.delete "RAKE_COLUMNS"
    end
  end

  def test_windows
    assert ! (@app.windows? && @app.unix?)
  end

  def test_loading_imports
    loader = util_loader

    @app.instance_eval do
      add_loader("dummy", loader)
      add_import("x.dummy")
      load_imports
    end

    # HACK no assertions
  end

  def test_building_imported_files_on_demand
    loader = util_loader

    @app.instance_eval do
      intern(Rake::Task, "x.dummy").enhance do loader.make_dummy end
      add_loader("dummy", loader)
      add_import("x.dummy")
      load_imports
    end

    # HACK no assertions
  end

  def test_handle_options_should_not_strip_options_from_argv
    assert !@app.options.trace

    argv = %w[--trace]
    @app.handle_options argv

    assert_includes argv, "--trace"
    assert @app.options.trace
  end

  def test_handle_options_trace_default_is_stderr
    @app.handle_options %w[--trace]

    assert_equal STDERR, @app.options.trace_output
    assert @app.options.trace
  end

  def test_handle_options_trace_overrides_to_stdout
    @app.handle_options %w[--trace=stdout]

    assert_equal STDOUT, @app.options.trace_output
    assert @app.options.trace
  end

  def test_handle_options_trace_does_not_eat_following_task_names
    assert !@app.options.trace

    argv = %w[--trace sometask]
    @app.handle_options argv

    assert argv.include?("sometask")
    assert @app.options.trace
  end

  def test_good_run
    ran = false

    @app.options.silent = true

    @app.instance_eval do
      intern(Rake::Task, "default").enhance { ran = true }
    end

    rakefile_default

    out, err = capture_io do
      @app.run %w[--rakelib=""]
    end

    assert ran
    assert_empty err
    assert_equal "DEFAULT\n", out
  end

  def test_runs_in_rakefile_directory_from_subdir
    rakefile_unittest
    Dir.chdir "subdir"
    @app = Rake::Application.new

    pwd = nil
    @app.define_task(Rake::Task, "default") { pwd = Dir.pwd }

    @app.run %w[--silent]

    assert_equal @tempdir, pwd
  end

  def test_display_task_run
    ran = false
    @app.last_description = "COMMENT"
    @app.define_task(Rake::Task, "default")
    out, = capture_io { @app.run %w[-f -s --tasks --rakelib=""] }
    assert @app.options.show_tasks
    assert ! ran
    assert_match(/rake default/, out)
    assert_match(/# COMMENT/, out)
  end

  def test_display_prereqs
    ran = false
    @app.last_description = "COMMENT"
    t = @app.define_task(Rake::Task, "default")
    t.enhance([:a, :b])
    @app.define_task(Rake::Task, "a")
    @app.define_task(Rake::Task, "b")
    out, = capture_io { @app.run %w[-f -s --prereqs --rakelib=""] }
    assert @app.options.show_prereqs
    assert ! ran
    assert_match(/rake a$/, out)
    assert_match(/rake b$/, out)
    assert_match(/rake default\n( *(a|b)\n){2}/m, out)
  end

  def test_bad_run
    @app.intern(Rake::Task, "default").enhance { fail }
    _, err = capture_io {
      assert_raises(SystemExit) { @app.run %w[-f -s --rakelib=""] }
    }
    assert_match(/see full trace/i, err)
  end

  def test_bad_run_with_trace
    @app.intern(Rake::Task, "default").enhance { fail }
    _, err = capture_io {
      @app.set_default_options
      assert_raises(SystemExit) { @app.run %w[-f -s -t] }
    }
    refute_match(/see full trace/i, err)
  end

  def test_bad_run_with_backtrace
    @app.intern(Rake::Task, "default").enhance { fail }
    _, err = capture_io {
      assert_raises(SystemExit) {
        @app.run %w[-f -s --backtrace]
      }
    }
    refute_match(/see full trace/, err)
  end

  CustomError = Class.new(RuntimeError)

  def test_bad_run_includes_exception_name
    @app.intern(Rake::Task, "default").enhance {
      raise CustomError, "intentional"
    }
    _, err = capture_io {
      assert_raises(SystemExit) {
        @app.run %w[-f -s]
      }
    }
    assert_match(/CustomError: intentional/, err)
  end

  def test_rake_error_excludes_exception_name
    @app.intern(Rake::Task, "default").enhance {
      fail "intentional"
    }
    _, err = capture_io {
      assert_raises(SystemExit) {
        @app.run %w[-f -s]
      }
    }
   refute_match(/RuntimeError/, err)
   assert_match(/intentional/, err)
  end

  def cause_supported?
    ex = StandardError.new
    ex.respond_to?(:cause)
  end

  def test_printing_original_exception_cause
    custom_error = Class.new(StandardError)
    @app.intern(Rake::Task, "default").enhance {
      begin
        raise custom_error, "Original Error"
      rescue custom_error
        raise custom_error, "Secondary Error"
      end
    }
    _ ,err = capture_io {
      assert_raises(SystemExit) {
        @app.run %w[-f -s]
      }
    }
    if cause_supported?
      assert_match(/Original Error/, err)
    end
    assert_match(/Secondary Error/, err)
  end

  def test_run_with_bad_options
    @app.intern(Rake::Task, "default").enhance { fail }
    assert_raises(SystemExit) {
      capture_io { @app.run %w[-f -s --xyzzy] }
    }
  end

  def test_standard_exception_handling_invalid_option
    out, err = capture_io do
      e = assert_raises SystemExit do
        @app.standard_exception_handling do
          raise OptionParser::InvalidOption, "blah"
        end
      end

      assert_equal 1, e.status
    end

    assert_empty out
    assert_equal "invalid option: blah\n", err
  end

  def test_standard_exception_handling_other
    out, err = capture_io do
      @app.set_default_options # reset trace output IO

      e = assert_raises SystemExit do
        @app.standard_exception_handling do
          raise "blah"
        end
      end

      assert_equal 1, e.status
    end

    assert_empty out
    assert_match "rake aborted!\n", err
    assert_match "blah\n", err
  end

  def test_standard_exception_handling_system_exit
    out, err = capture_io do
      e = assert_raises SystemExit do
        @app.standard_exception_handling do
          exit 0
        end
      end

      assert_equal 0, e.status
    end

    assert_empty out
    assert_empty err
  end

  def test_standard_exception_handling_system_exit_nonzero
    out, err = capture_io do
      e = assert_raises SystemExit do
        @app.standard_exception_handling do
          exit 5
        end
      end

      assert_equal 5, e.status
    end

    assert_empty out
    assert_empty err
  end

  def util_loader
    loader = Object.new

    loader.instance_variable_set :@load_called, false
    def loader.load(arg)
      raise ArgumentError, arg unless arg == "x.dummy"
      @load_called = true
    end

    loader.instance_variable_set :@make_dummy_called, false
    def loader.make_dummy
      @make_dummy_called = true
    end

    loader
  end

end
