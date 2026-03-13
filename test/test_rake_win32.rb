# frozen_string_literal: true
require File.expand_path("../helper", __FILE__)

class TestRakeWin32 < Rake::TestCase # :nodoc:

  def test_win32_backtrace_with_different_case
    ex = nil
    begin
      raise "test exception"
    rescue => ex
    end

    ex.set_backtrace ["abc", "rakefile"]

    rake = Rake::Application.new
    rake.options.trace = true
    rake.instance_variable_set(:@rakefile, "Rakefile")

    _, err = capture_output {
      rake.set_default_options # reset trace output IO

      rake.display_error_message(ex)
    }

    assert_match(/rakefile/, err)
  end

end
