
module Rake end
module Rake::CompTree
  module Diagnostic
    module_function

    def show(desc = nil, stream = STDOUT, &block)
      if desc
        stream.puts(desc)
      end
      if block
        expression = block.call
        result = eval(expression, block.binding)
        stream.printf("%-16s => %s\n", expression, result.inspect)
        result
      end
    end

    if $DEBUG
      def debug
        yield
      end

      def debugging?
        true
      end

      def trace(desc = nil, &block)
        show(desc, STDERR, &block)
      end
    else
      def debug ; end
      def debugging? ; end
      def trace(*args) ; end
    end
  end
end

