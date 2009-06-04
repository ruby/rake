module Rake

  # Rakefile are evaluated in the Rake::Environment module space.  Top
  # level rake functions (e.g. :task, :file) are available in this
  # environment.
  module Environment
    extend Rake::DSL

    class << self
      def load_rakefile(rakefile_path)
        rakefile = open(rakefile_path) { |f| f.read }
        load_string(rakefile, rakefile_path)
      end

      def load_string(code, file_name=nil)
        module_eval(code, file_name || "(eval)")
      end

      def run(&block)
        module_eval(&block)
      end
    end
  end
end
