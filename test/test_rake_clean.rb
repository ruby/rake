# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)
require "rake/clean"

class TestRakeClean < Rake::TestCase # :nodoc:
  def test_clean
    if RUBY_ENGINE == "truffleruby" and RUBY_ENGINE_VERSION.start_with?("19.3.")
      load "rake/clean.rb" # TruffleRuby 19.3 does not set self correctly with wrap=true
    else
      load "rake/clean.rb", true
    end

    assert Rake::Task["clean"], "Should define clean"
    assert Rake::Task["clobber"], "Should define clobber"
    assert Rake::Task["clobber"].prerequisites.include?("clean"),
      "Clobber should require clean"
  end

  def test_cleanup
    file_name = create_undeletable_file

    out, _ = capture_output do
      Rake::Cleaner.cleanup(file_name, verbose: false)
    end
    assert_match(/failed to remove/i, out)

  ensure
    remove_undeletable_file
  end

  def test_cleanup_ignores_missing_files
    file_name = File.join(@tempdir, "missing_directory", "no_such_file")

    out, _ = capture_output do
      Rake::Cleaner.cleanup(file_name, verbose: false)
    end
    refute_match(/failed to remove/i, out)
  end

  def test_cleanup_trace
    file_name = create_file

    out, err = capture_output do
      with_trace true do
        Rake::Cleaner.cleanup(file_name)
      end
    end

    if err == ""
      # Current FileUtils
      assert_equal "rm -r #{file_name}\n", out
    else
      # Old FileUtils
      assert_equal "", out
      assert_equal "rm -r #{file_name}\n", err
    end
  end

  def test_cleanup_without_trace
    file_name = create_file

    out, err = capture_output do
      with_trace false do
        Rake::Cleaner.cleanup(file_name)
      end
    end
    assert_empty out
    assert_empty err
  end

  def test_cleanup_opt_overrides_trace_silent
    file_name = create_file

    out, err = capture_output do
      with_trace true do
        Rake::Cleaner.cleanup(file_name, verbose: false)
      end
    end
    assert_empty out
    assert_empty err
  end

  def test_cleanup_opt_overrides_trace_verbose
    file_name = create_file

    out, err = capture_output do
      with_trace false do
        Rake::Cleaner.cleanup(file_name, verbose: true)
      end
    end

    if err == ""
      assert_equal "rm -r #{file_name}\n", out
    else
      assert_equal "", out
      assert_equal "rm -r #{file_name}\n", err
    end
  end

  private

  def create_file
    dir_name = File.join(@tempdir, "deletedir")
    file_name = File.join(dir_name, "deleteme")
    FileUtils.mkdir(dir_name)
    FileUtils.touch(file_name)
    file_name
  end

  def create_undeletable_file
    dir_name = File.join(@tempdir, "deletedir")
    file_name = File.join(dir_name, "deleteme")
    FileUtils.mkdir(dir_name)
    FileUtils.touch(file_name)
    FileUtils.chmod(0, file_name)
    FileUtils.chmod(0, dir_name)
    begin
      FileUtils.chmod(0644, file_name)
    rescue
      file_name
    else
      skip "Permission to delete files is different on this system"
    end
  end

  def remove_undeletable_file
    dir_name = File.join(@tempdir, "deletedir")
    file_name = File.join(dir_name, "deleteme")
    FileUtils.chmod(0777, dir_name)
    FileUtils.chmod(0777, file_name)
    Rake::Cleaner.cleanup(file_name, verbose: false)
    Rake::Cleaner.cleanup(dir_name, verbose: false)
  end

  def with_trace(value)
    old, Rake.application.options.trace =
      Rake.application.options.trace, value

    # FileUtils caches the $stderr object, which breaks capture_output et. al.
    # We hack it here where it's convenient to do so.
    Rake::Cleaner.instance_variable_set :@fileutils_output, nil
    yield
  ensure
    Rake.application.options.trace = old
  end
end
