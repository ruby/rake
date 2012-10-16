require File.expand_path('../helper', __FILE__)

class TestSignal < Rake::TestCase

  def test_signal
    puts "DBG: PARENT $$=#{$$.inspect}"
    fork {
      puts "DBG: CHILD $$=#{$$.inspect}"
      Process.kill "TERM", $$
    }
    Process.wait
    puts "DBG: $?.respond_to?(:signaled?)=#{$?.respond_to?(:signaled?).inspect}"
    puts "DBG: $?.signaled?=#{$?.signaled?.inspect}" if $?.respond_to?(:signaled?)
    puts "DBG: $?=#{$?.inspect}"
  end
end
