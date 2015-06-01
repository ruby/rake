require 'thread'

module Rake
  class SynchronizedOutput
    def self.wrap(io)
      return io if self === io
      new(io)
    end

    def initialize(io, lock = Mutex.new)
      @io = io
      @lock = lock
    end

    def method_missing(name, *args, &block)
      @lock.synchronize do
        @io.send(name, *args, &block)
      end
    end

    def respond_to?(name, private = false)
      @io.respond_to?(name, private)
    end
  end
end
