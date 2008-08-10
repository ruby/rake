#!/usr/bin/env ruby

module Rake

  # Makefile loader to be used with the import file loader.
  class MakefileLoader

    # Load the makefile dependencies in +fn+.
    def load(fn)
      open(fn) do |mf|
        lines = mf.read
        lines.gsub!(/#[^\n]*\n/m, "")
        lines.gsub!(/\\\n/, ' ')
        lines.split("\n").each do |line|
          process_line(line)
        end
      end
    end

    private

    # Process one logical line of makefile data.
    def process_line(line)
      file_task, args = line.split(':')
      return if args.nil?
      file_task.strip!
      dependents = args.split
      file file_task => dependents
    end
  end

  # Install the handler
  Rake.application.add_loader('mf', MakefileLoader.new)
end
