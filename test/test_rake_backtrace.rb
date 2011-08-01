require File.expand_path('../helper', __FILE__)
require 'open3'

class TestRakeBacktrace < Rake::TestCase
  # TODO: factor out similar code in test_rake_functional.rb
  def rake(*args)
    lib = File.join(@orig_PWD, "lib")
    bin_rake = File.join(@orig_PWD, "bin", "rake")
    Open3.popen3(RUBY, "-I", lib, bin_rake, *args) { |_, _, err, _| err.read }
  end

  def invoke(task_name)
    rake task_name.to_s
  end

  def test_single_collapse
    rakefile %q{
      task :foo do
        raise "foooo!"
      end
    }

    lines = invoke(:foo).split("\n")

    assert_equal "rake aborted!", lines[0]
    assert_equal "foooo!", lines[1]
    assert_match %r!\A#{Regexp.quote Dir.pwd}/Rakefile:3!, lines[2]
    assert_match %r!\ATasks:!, lines[3]
  end

  def test_multi_collapse
    rakefile %q{
      task :foo do
        Rake.application.invoke_task(:bar)
      end
      task :bar do
        raise "barrr!"
      end
    }

    lines = invoke(:foo).split("\n")

    assert_equal "rake aborted!", lines[0]
    assert_equal "barrr!", lines[1]
    assert_match %r!\A#{Regexp.quote Dir.pwd}/Rakefile:6!, lines[2]
    assert_match %r!\A#{Regexp.quote Dir.pwd}/Rakefile:3!, lines[3]
    assert_match %r!\ATasks:!, lines[4]
  end
end
