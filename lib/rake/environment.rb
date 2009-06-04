module Rake

  # Rakefile are evaluated in the Rake::Environment module space.  Top
  # level rake functions (e.g. :task, :file) are available in this
  # environment.
  module Environment
    extend Rake::DSL

    class << self
      def load_string(code)
        module_eval(code)
      end
    end
  end
end
