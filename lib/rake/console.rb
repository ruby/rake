# frozen_string_literal: true
module Rake
  module Console
    def self.start
      require "irb"

      puts "Rake console, version #{Rake::VERSION}"
      Rake.application.load_rakefile
      ARGV.clear
      IRB.start
      exit
    end
  end
end
