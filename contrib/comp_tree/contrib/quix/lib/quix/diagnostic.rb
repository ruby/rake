
require 'rake/comp_tree/quix/builtin/kernel/tap'

module Rake::CompTree::Quix
  module Diagnostic
    def show(desc = nil, stream = STDOUT, &block)
      if desc
        stream.puts(desc)
      end
      if block
        expression = block.call
        eval(expression, block.binding).tap { |result|
          stream.printf("%-16s => %s\n", expression, result.inspect)
        }
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
        if desc
          show("#{desc}.".sub(%r!\.\.+\Z!, ""), STDERR, &block)
        else
          show(nil, STDERR, &block)
        end
      end
    else
      # non-$DEBUG
      def debug ; end
      def debugging? ; end
      def trace(*args) ; end
    end

    extend self
  end
end

