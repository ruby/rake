require_relative 'helper'

class TestRakeCpuCounter < Rake::TestCase

  def setup
    super

    @cpu_counter = Rake::CpuCounter.new
  end

  def test_in_path_command
    ruby     = File.basename Gem.ruby
    ruby_dir = File.dirname  Gem.ruby

    begin
      orig_path, ENV['PATH'] =
        ENV['PATH'], [ruby_dir, *ENV['PATH']].join(File::PATH_SEPARATOR)

      assert_equal ruby, @cpu_counter.in_path_command(ruby)
    ensure
      ENV['PATH'] = orig_path
    end
  rescue Errno::ENOENT => e
    raise unless e.message =~ /\bwhich\b/

    skip 'cannot find which for this test'
  end

  def test_run
    ruby     = File.basename Gem.ruby
    ruby_dir = File.dirname  Gem.ruby

    begin
      orig_path, ENV['PATH'] =
        ENV['PATH'], [ruby_dir, *ENV['PATH']].join(File::PATH_SEPARATOR)

      assert_equal 7, @cpu_counter.run(ruby, '-e "puts 3 + 4"')
    ensure
      ENV['PATH'] = orig_path
    end
  end

end

