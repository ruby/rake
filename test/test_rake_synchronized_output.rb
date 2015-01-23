require File.expand_path('../helper', __FILE__)

module Rake
  class TestSynchronizedOutput < TestCase
    def setup
      super
      @inner_io = StringIO.new
      @wrapper = SynchronizedOutput.wrap(inner_io)
    end

    attr_reader :inner_io, :lock, :wrapper

    def test_only_wraps_once
      assert_same wrapper, SynchronizedOutput.wrap(wrapper)
    end

    def test_forwards_to_inner_io
      wrapper.puts("Hello")
      assert_equal "Hello\n", inner_io.string
    end

    def test_correctly_answers_respond_to
      assert wrapper.respond_to?(:puts)
    end

    def test_locks_while_forwarding
      lock = FakeLock.new
      io = FakeIO.new(lock)
      @wrapper = SynchronizedOutput.new(io, lock)

      wrapper.puts("Hello")

      assert io.was_locked?
    end

    private

    class FakeLock
      def initialize
        @locked = false
      end

      def synchronize
        @locked = true
        yield
      ensure
        @locked = false
      end

      def is_locked?
        @locked
      end
    end

    class FakeIO
      def initialize(lock)
        @lock = lock
        @was_locked = false
      end

      def puts(*)
        @was_locked = @lock.is_locked?
      end

      def was_locked?
        @was_locked
      end
    end
  end
end
