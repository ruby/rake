require File.expand_path('../helper', __FILE__)

TESTING_REQUIRE = [ ]

######################################################################
class TestRakeApplication < Rake::TestCase
  include InEnvironment

  def setup
    super

    @app = Rake::Application.new
    @app.options.rakelib = []
    Rake::TaskManager.record_task_metadata = true
  end

  def teardown
    Rake::TaskManager.record_task_metadata = false

    super
  end

  def test_constant_warning
    _, err = capture_io do @app.instance_eval { const_warning("Task") } end
    assert_match(/warning/i, err)
    assert_match(/deprecated/i, err)
    assert_match(/Task/i, err)
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
    in_environment('RAKE_COLUMNS' => '80') do
      @app.options.show_tasks = :tasks
      @app.options.show_task_pattern = //
      @app.last_description = "1234567890" * 8
      @app.define_task(Rake::Task, "t")
      out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
      assert_match(/^rake t/, out)
      assert_match(/# 12345678901234567890123456789012345678901234567890123456789012345\.\.\./, out)
    end
  end

  def test_display_tasks_with_task_name_wider_than_tty_display
    in_environment('RAKE_COLUMNS' => '80') do
      @app.options.show_tasks = :tasks
      @app.options.show_task_pattern = //
      task_name = "task name" * 80
      @app.last_description = "something short"
      @app.define_task(Rake::Task, task_name )
      out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
      # Ensure the entire task name is output and we end up showing no description
      assert_match(/rake #{task_name}  # .../, out)
    end
  end

  def test_display_tasks_with_very_long_task_name_to_a_non_tty_shows_name_and_comment
    @app.options.show_tasks = :tasks
    @app.options.show_task_pattern = //
    @app.tty_output = false
    description = "something short"
    task_name = "task name" * 80
    @app.last_description = "something short"
    @app.define_task(Rake::Task, task_name )
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

  def test_display_tasks_with_long_comments_to_a_non_tty_with_columns_set_truncates_comments
    in_environment("RAKE_COLUMNS" => '80') do
      @app.options.show_tasks = :tasks
      @app.options.show_task_pattern = //
      @app.tty_output = false
      @app.last_description = "1234567890" * 8
      @app.define_task(Rake::Task, "t")
      out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
      assert_match(/^rake t/, out)
      assert_match(/# 12345678901234567890123456789012345678901234567890123456789012345\.\.\./, out)
    end
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
    @app['t'].locations << "HERE:1"
    out, = capture_io do @app.instance_eval { display_tasks_and_comments } end
    assert_match(/^rake t +[^:]+:\d+ *$/, out)
  end

  def test_finding_rakefile
    assert_match(/Rakefile/i, @app.instance_eval { have_rakefile })
  end

  def test_not_finding_rakefile
    @app.instance_eval { @rakefiles = ['NEVER_FOUND'] }
    assert( ! @app.instance_eval do have_rakefile end )
    assert_nil @app.rakefile
  end

  def test_load_rakefile
    in_environment("PWD" => "test/data/unittest") do
      @app.instance_eval do
        handle_options
        options.silent = true
        load_rakefile
      end
      assert_equal "rakefile", @app.rakefile.downcase
      assert_match(%r(unittest$), Dir.pwd)
    end
  end

  def test_load_rakefile_doesnt_print_rakefile_directory_from_same_dir
    in_environment("PWD" => "test/data/unittest") do
      _, err = capture_io do
        @app.instance_eval do
          @original_dir = File.expand_path(".") # pretend we started from the unittest dir
          raw_load_rakefile
        end
      end
      _, location = @app.find_rakefile_location
      refute_match(/\(in #{location}\)/, err)
    end
  end

  def test_load_rakefile_from_subdir
    in_environment("PWD" => "test/data/unittest/subdir") do
      @app.instance_eval do
        handle_options
        options.silent = true
        load_rakefile
      end
      assert_equal "rakefile", @app.rakefile.downcase
      assert_match(%r(unittest$), Dir.pwd)
    end
  end

  def test_load_rakefile_prints_rakefile_directory_from_subdir
    in_environment("PWD" => "test/data/unittest/subdir") do
      _, err = capture_io do
        @app.instance_eval do
          raw_load_rakefile
        end
      end
      _, location = @app.find_rakefile_location
      assert_match(/\(in #{location}\)/, err)
    end
  end

  def test_load_rakefile_doesnt_print_rakefile_directory_from_subdir_if_silent
    in_environment("PWD" => "test/data/unittest/subdir") do
      _, err = capture_io do
        @app.instance_eval do
          handle_options
          options.silent = true
          raw_load_rakefile
        end
      end
      _, location = @app.find_rakefile_location
      refute_match(/\(in #{location}\)/, err)
    end
  end

  def test_load_rakefile_not_found
    in_environment("PWD" => "/", "RAKE_SYSTEM" => 'not_exist') do
      @app.instance_eval do
        handle_options
        options.silent = true
      end
      ex = assert_raises(RuntimeError) do
        @app.instance_eval do raw_load_rakefile end
      end
      assert_match(/no rakefile found/i, ex.message)
    end
  end

  def test_load_from_system_rakefile
    in_environment('RAKE_SYSTEM' => 'test/data/sys') do
      @app.options.rakelib = []
      @app.instance_eval do
        handle_options
        options.silent = true
        options.load_system = true
        options.rakelib = []
        load_rakefile
      end
      assert_equal "test/data/sys", @app.system_dir
      assert_nil @app.rakefile
    end
  end

  def test_load_from_calculated_system_rakefile
    flexmock(@app, :standard_system_dir => "__STD_SYS_DIR__")
    in_environment('RAKE_SYSTEM' => nil) do
      @app.options.rakelib = []
      @app.instance_eval do
        handle_options
        options.silent = true
        options.load_system = true
        options.rakelib = []
        load_rakefile
      end
      assert_equal "__STD_SYS_DIR__", @app.system_dir
    end
  end

  def test_windows
    assert ! (@app.windows? && @app.unix?)
  end

  def test_loading_imports
    mock = flexmock("loader")
    mock.should_receive(:load).with("x.dummy").once
    @app.instance_eval do
      add_loader("dummy", mock)
      add_import("x.dummy")
      load_imports
    end
  end

  def test_building_imported_files_on_demand
    mock = flexmock("loader")
    mock.should_receive(:load).with("x.dummy").once
    mock.should_receive(:make_dummy).with_no_args.once
    @app.instance_eval do
      intern(Rake::Task, "x.dummy").enhance do mock.make_dummy end
        add_loader("dummy", mock)
      add_import("x.dummy")
      load_imports
    end
  end

  def test_handle_options_should_strip_options_from_ARGV
    assert !@app.options.trace

    valid_option = '--trace'
    ARGV.clear
    ARGV << valid_option

    @app.handle_options

    assert !ARGV.include?(valid_option)
    assert @app.options.trace
  end

  def test_good_run
    ran = false
    ARGV.clear
    ARGV << '--rakelib=""'
    @app.options.silent = true
    @app.instance_eval do
      intern(Rake::Task, "default").enhance { ran = true }
    end
    in_environment("PWD" => "test/data/default") do
      @app.run
    end
    assert ran
  end

  def test_display_task_run
    ran = false
    ARGV.clear
    ARGV << '-f' << '-s' << '--tasks' << '--rakelib=""'
    @app.last_description = "COMMENT"
    @app.define_task(Rake::Task, "default")
    out, = capture_io { @app.run }
    assert @app.options.show_tasks
    assert ! ran
    assert_match(/rake default/, out)
    assert_match(/# COMMENT/, out)
  end

  def test_display_prereqs
    ran = false
    ARGV.clear
    ARGV << '-f' << '-s' << '--prereqs' << '--rakelib=""'
    @app.last_description = "COMMENT"
    t = @app.define_task(Rake::Task, "default")
    t.enhance([:a, :b])
    @app.define_task(Rake::Task, "a")
    @app.define_task(Rake::Task, "b")
    out, = capture_io { @app.run }
    assert @app.options.show_prereqs
    assert ! ran
    assert_match(/rake a$/, out)
    assert_match(/rake b$/, out)
    assert_match(/rake default\n( *(a|b)\n){2}/m, out)
  end

  def test_bad_run
    @app.intern(Rake::Task, "default").enhance { fail }
    ARGV.clear
    ARGV << '-f' << '-s' <<  '--rakelib=""'
    assert_raises(SystemExit) {
      _, err = capture_io { @app.run }
      assert_match(/see full trace/, err)
    }
  ensure
    ARGV.clear
  end

  def test_bad_run_with_trace
    @app.intern(Rake::Task, "default").enhance { fail }
    ARGV.clear
    ARGV << '-f' << '-s' << '-t'
    assert_raises(SystemExit) {
      _, err = capture_io { @app.run }
      refute_match(/see full trace/, err)
    }
  ensure
    ARGV.clear
  end

  def test_run_with_bad_options
    @app.intern(Rake::Task, "default").enhance { fail }
    ARGV.clear
    ARGV << '-f' << '-s' << '--xyzzy'
    assert_raises(SystemExit) {
      capture_io { @app.run }
    }
  ensure
    ARGV.clear
  end

  def test_deprecation_message
    in_environment do
      _, err = capture_io do
        @app.deprecate("a", "b", "c")
      end
      assert_match(/'a' is deprecated/i, err)
      assert_match(/use 'b' instead/i, err)
      assert_match(/at c$/i, err)
    end
  end
end


######################################################################
class TestRakeApplicationOptions < Rake::TestCase

  def setup
    super

    clear_argv
    Rake::FileUtilsExt.verbose_flag = false
    Rake::FileUtilsExt.nowrite_flag = false
    TESTING_REQUIRE.clear
  end

  def teardown
    clear_argv
    Rake::FileUtilsExt.verbose_flag = false
    Rake::FileUtilsExt.nowrite_flag = false

    super
  end

  def clear_argv
    while ! ARGV.empty?
      ARGV.pop
    end
  end

  def test_default_options
    in_environment("RAKEOPT" => nil) do
      opts = command_line
      assert_nil opts.classic_namespace
      assert_nil opts.dryrun
      assert_nil opts.ignore_system
      assert_nil opts.load_system
      assert_nil opts.nosearch
      assert_equal ['rakelib'], opts.rakelib
      assert_nil opts.show_prereqs
      assert_nil opts.show_task_pattern
      assert_nil opts.show_tasks
      assert_nil opts.silent
      assert_nil opts.trace
      assert_equal ['rakelib'], opts.rakelib
      assert ! Rake::FileUtilsExt.verbose_flag
      assert ! Rake::FileUtilsExt.nowrite_flag
    end
  end

  def test_dry_run
    in_environment do
      flags('--dry-run', '-n') do |opts|
        assert opts.dryrun
        assert opts.trace
        assert Rake::FileUtilsExt.verbose_flag
        assert Rake::FileUtilsExt.nowrite_flag
      end
    end
  end

  def test_describe
    in_environment do
      flags('--describe') do |opts|
        assert_equal :describe, opts.show_tasks
        assert_equal(//.to_s, opts.show_task_pattern.to_s)
      end
    end
  end

  def test_describe_with_pattern
    in_environment do
      flags('--describe=X') do |opts|
        assert_equal :describe, opts.show_tasks
        assert_equal(/X/.to_s, opts.show_task_pattern.to_s)
      end
    end
  end

  def test_execute
    in_environment do
      $xyzzy = 0
      flags('--execute=$xyzzy=1', '-e $xyzzy=1') do |opts|
        assert_equal 1, $xyzzy
        assert_equal :exit, @exit
        $xyzzy = 0
      end
    end
  end

  def test_execute_and_continue
    in_environment do
      $xyzzy = 0
      flags('--execute-continue=$xyzzy=1', '-E $xyzzy=1') do |opts|
        assert_equal 1, $xyzzy
        refute_equal :exit, @exit
        $xyzzy = 0
      end
    end
  end

  def test_execute_and_print
    in_environment do
      $xyzzy = 0
      out, = capture_io do
        flags('--execute-print=$xyzzy="pugh"', '-p $xyzzy="pugh"') do |opts|
          assert_equal 'pugh', $xyzzy
          assert_equal :exit, @exit
          $xyzzy = 0
        end
      end

      assert_match(/^pugh$/, out)
    end
  end

  def test_help
    in_environment do
      out, = capture_io do
        flags '--help', '-H', '-h'
      end

      assert_match(/\Arake/, out)
      assert_match(/\boptions\b/, out)
      assert_match(/\btargets\b/, out)
      assert_equal :exit, @exit
    end
  end

  def test_libdir
    in_environment do
      flags(['--libdir', 'xx'], ['-I', 'xx'], ['-Ixx']) do |opts|
        $:.include?('xx')
      end
    end
  ensure
    $:.delete('xx')
  end

  def test_rakefile
    in_environment do
      flags(['--rakefile', 'RF'], ['--rakefile=RF'], ['-f', 'RF'], ['-fRF']) do |opts|
        assert_equal ['RF'], @app.instance_eval { @rakefiles }
      end
    end
  end

  def test_rakelib
    in_environment do
      flags(['--rakelibdir', 'A:B:C'], ['--rakelibdir=A:B:C'], ['-R', 'A:B:C'], ['-RA:B:C']) do |opts|
        assert_equal ['A', 'B', 'C'], opts.rakelib
      end
    end
  end

  def test_require
    in_environment do
      flags(['--require', 'test/reqfile'], '-rtest/reqfile2', '-rtest/reqfile3') do |opts|
      end
      assert TESTING_REQUIRE.include?(1)
      assert TESTING_REQUIRE.include?(2)
      assert TESTING_REQUIRE.include?(3)
      assert_equal 3, TESTING_REQUIRE.size
    end
  end

  def test_missing_require
    in_environment do
      ex = assert_raises(LoadError) do
        flags(['--require', 'test/missing']) do |opts|
        end
      end
      assert_match(/such file/, ex.message)
      assert_match(/test\/missing/, ex.message)
    end
  end

  def test_prereqs
    in_environment do
      flags('--prereqs', '-P') do |opts|
        assert opts.show_prereqs
      end
    end
  end

  def test_quiet
    in_environment do
      flags('--quiet', '-q') do |opts|
        assert ! Rake::FileUtilsExt.verbose_flag
        assert ! opts.silent
      end
    end
  end

  def test_no_search
    in_environment do
      flags('--nosearch', '--no-search', '-N') do |opts|
        assert opts.nosearch
      end
    end
  end

  def test_silent
    in_environment do
      flags('--silent', '-s') do |opts|
        assert ! Rake::FileUtilsExt.verbose_flag
        assert opts.silent
      end
    end
  end

  def test_system
    in_environment do
      flags('--system', '-g') do |opts|
        assert opts.load_system
      end
    end
  end

  def test_no_system
    in_environment do
      flags('--no-system', '-G') do |opts|
        assert opts.ignore_system
      end
    end
  end

  def test_trace
    in_environment do
      flags('--trace', '-t') do |opts|
        assert opts.trace
        assert Rake::FileUtilsExt.verbose_flag
        assert ! Rake::FileUtilsExt.nowrite_flag
      end
    end
  end

  def test_trace_rules
    in_environment do
      flags('--rules') do |opts|
        assert opts.trace_rules
      end
    end
  end

  def test_tasks
    in_environment do
      flags('--tasks', '-T') do |opts|
        assert_equal :tasks, opts.show_tasks
        assert_equal(//.to_s, opts.show_task_pattern.to_s)
      end
      flags(['--tasks', 'xyz'], ['-Txyz']) do |opts|
        assert_equal :tasks, opts.show_tasks
        assert_equal(/xyz/.to_s, opts.show_task_pattern.to_s)
      end
    end
  end

  def test_where
    in_environment do
      flags('--where', '-W') do |opts|
        assert_equal :lines, opts.show_tasks
        assert_equal(//.to_s, opts.show_task_pattern.to_s)
      end
      flags(['--where', 'xyz'], ['-Wxyz']) do |opts|
        assert_equal :lines, opts.show_tasks
        assert_equal(/xyz/.to_s, opts.show_task_pattern.to_s)
      end
    end
  end

  def test_no_deprecated_messages
    in_environment do
      flags('--no-deprecation-warnings', '-X') do |opts|
        assert opts.ignore_deprecate
      end
    end
  end

  def test_verbose
    in_environment do
      out, = capture_io do
        flags('--verbose', '-V') do |opts|
          assert Rake::FileUtilsExt.verbose_flag
          assert ! opts.silent
        end
      end

      assert_equal "rake, version 0.9.0\n", out
    end
  end

  def test_version
    in_environment do
      out, = capture_io do
        flags '--version', '-V'
      end

      assert_match(/\bversion\b/, out)
      assert_match(/\b#{RAKEVERSION}\b/, out)
      assert_equal :exit, @exit
    end
  end

  def test_classic_namespace
    in_environment do
      _, err = capture_io do
        flags(['--classic-namespace'],
              ['-C', '-T', '-P', '-n', '-s', '-t']) do |opts|
          assert opts.classic_namespace
          assert_equal opts.show_tasks, $show_tasks
          assert_equal opts.show_prereqs, $show_prereqs
          assert_equal opts.trace, $trace
          assert_equal opts.dryrun, $dryrun
          assert_equal opts.silent, $silent
        end
      end

      assert_match(/deprecated/, err)
    end
  end

  def test_bad_option
    in_environment do
      _, err = capture_io do
        ex = assert_raises(OptionParser::InvalidOption) do
          flags('--bad-option')
        end
        if ex.message =~ /^While/ # Ruby 1.9 error message
          assert_match(/while parsing/i, ex.message)
        else                      # Ruby 1.8 error message
          assert_match(/(invalid|unrecognized) option/i, ex.message)
          assert_match(/--bad-option/, ex.message)
        end
      end
      assert_equal '', err
    end
  end

  def test_task_collection
    command_line("a", "b")
    assert_equal ["a", "b"], @tasks.sort
  end

  def test_default_task_collection
    command_line()
    assert_equal ["default"], @tasks
  end

  def test_environment_definition
    ENV.delete('TESTKEY')
    command_line("a", "TESTKEY=12")
    assert_equal ["a"], @tasks.sort
    assert '12', ENV['TESTKEY']
  end

  private

  def flags(*sets)
    sets.each do |set|
      ARGV.clear

      @exit = catch(:system_exit) { command_line(*set) }

      yield(@app.options) if block_given?
    end
  end

  def command_line(*options)
    options.each do |opt| ARGV << opt end
    @app = Rake::Application.new
    def @app.exit(*args)
      throw :system_exit, :exit
    end
    @app.instance_eval do
      handle_options
      collect_tasks
    end
    @tasks = @app.top_level_tasks
    @app.options
  end
end

class TestRakeTaskArgumentParsing < Rake::TestCase
  def setup
    super

    @app = Rake::Application.new
  end

  def test_name_only
    name, args = @app.parse_task_string("name")
    assert_equal "name", name
    assert_equal [], args
  end

  def test_empty_args
    name, args = @app.parse_task_string("name[]")
    assert_equal "name", name
    assert_equal [], args
  end

  def test_one_argument
    name, args = @app.parse_task_string("name[one]")
    assert_equal "name", name
    assert_equal ["one"], args
  end

  def test_two_arguments
    name, args = @app.parse_task_string("name[one,two]")
    assert_equal "name", name
    assert_equal ["one", "two"], args
  end

  def test_can_handle_spaces_between_args
    name, args = @app.parse_task_string("name[one, two,\tthree , \tfour]")
    assert_equal "name", name
    assert_equal ["one", "two", "three", "four"], args
  end

  def test_keeps_embedded_spaces
    name, args = @app.parse_task_string("name[a one ana, two]")
    assert_equal "name", name
    assert_equal ["a one ana", "two"], args
  end

end

class TestRakeTaskArgumentParsing < Rake::TestCase

  def test_terminal_width_using_env
    app = Rake::Application.new
    in_environment('RAKE_COLUMNS' => '1234') do
      assert_equal 1234, app.terminal_width
    end
  end

  def test_terminal_width_using_stty
    app = Rake::Application.new
    flexmock(app,
      :unix? => true,
      :dynamic_width_stty => 1235,
      :dynamic_width_tput => 0)
    in_environment('RAKE_COLUMNS' => nil) do
      assert_equal 1235, app.terminal_width
    end
  end

  def test_terminal_width_using_tput
    app = Rake::Application.new
    flexmock(app,
      :unix? => true,
      :dynamic_width_stty => 0,
      :dynamic_width_tput => 1236)
    in_environment('RAKE_COLUMNS' => nil) do
      assert_equal 1236, app.terminal_width
    end
  end

  def test_terminal_width_using_hardcoded_80
    app = Rake::Application.new
    flexmock(app, :unix? => false)
    in_environment('RAKE_COLUMNS' => nil) do
      assert_equal 80, app.terminal_width
    end
  end

  def test_terminal_width_with_failure
    app = Rake::Application.new
    flexmock(app).should_receive(:unix?).and_throw(RuntimeError)
    in_environment('RAKE_COLUMNS' => nil) do
      assert_equal 80, app.terminal_width
    end
  end

  def test_no_rakeopt
    in_environment do
      ARGV << '--trace'
      app = Rake::Application.new
      app.init
      assert !app.options.silent
    end
  end

  def test_rakeopt_with_blank_options
    in_environment("RAKEOPT" => "") do
      ARGV << '--trace'
      app = Rake::Application.new
      app.init
      assert !app.options.silent
    end
  end

  def test_rakeopt_with_silent_options
    in_environment("RAKEOPT" => "-s") do
      app = Rake::Application.new
      app.init
      assert app.options.silent
    end
  end
end
