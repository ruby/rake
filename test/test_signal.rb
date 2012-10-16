require File.expand_path('../helper', __FILE__)

class TestSignal < Rake::TestCase

  def test_signal
    puts "DBG: PARENT $$=#{$$.inspect}"
    fork {
      puts "DBG: CHILD $$=#{$$.inspect}"
      system "ruby -e 'puts $$; Process.kill \"TERM\", $$'"
    }
    Process.wait
    status = $?
    puts "DBG: status.respond_to?(:signaled?)=#{status.respond_to?(:signaled?).inspect}"
    puts "DBG: status.signaled?=#{status.signaled?.inspect}" if status.respond_to?(:signaled?)
    puts "DBG: status=#{status.inspect}"
  end
end
