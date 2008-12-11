
require 'thread'

module Kernel
  def singleton_class
    class << self
      self
    end
  end

  def let
    yield self
  end

  unless respond_to? :tap
    def tap
      yield self
      self
    end
  end

  private

  def with_warnings(value = true)
    previous = $VERBOSE
    $VERBOSE = value
    begin
      yield
    ensure
      $VERBOSE = previous
    end
  end

  def no_warnings(&block)
    with_warnings(false, &block)
  end

  def abort_on_exception(value = true)
    previous = Thread.abort_on_exception
    Thread.abort_on_exception = value
    begin
      yield
    ensure
      Thread.abort_on_exception = previous
    end
  end

  let {
    method_name = :gensym
    mutex = Mutex.new
    count = 0

    define_method(method_name) { |*args|
      prefix =
        case args.size
        when 0
          :G
        when 1
          args.first
        else
          raise ArgumentError,
            "wrong number of arguments (#{args.size} for 1)"
        end

      mutex.synchronize {
        count += 1
      }
      :"#{prefix}#{count}"
    }
    private method_name
  }
end
