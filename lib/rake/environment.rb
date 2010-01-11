require 'rake/dsl_definition'

module Rake

  # Rakefile are evaluated in the Rake::Environment module space.  Top
  # level rake functions (e.g. :task, :file) are available in this
  # environment.
  module Environment
    extend Rake::DSL

    class << self
      # Load a rakefile from the given path.  The Rakefile is loaded
      # in an environment that includes the Rake DSL methods.
      def load_rakefile(rakefile_path)
        rakefile = open(rakefile_path) { |f| f.read }
        load_string(rakefile, rakefile_path)
      end

      # Load a string of code in the Rake DSL environment.  If the
      # string comes from a file, include the file path so that proper
      # line numbers references may be retained.
      def load_string(code, file_name=nil)
        module_eval(code, file_name || "(eval)")
      end

      # Run a block of code in the Rake DSL environment.
      def run(&block)
        module_eval(&block)
      end
    end
  end

  # Run the code block in an environment including the Rake DSL
  # commands.
  def DSL.environment(&block)
    Rake::Environment.run(&block)
  end
end

    
