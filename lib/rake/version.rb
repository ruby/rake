module Rake
  VERSION = '11.3.0'

  module Version # :nodoc: all
    MAJOR, MINOR, BUILD, *OTHER = Rake::VERSION.split '.'

    NUMBERS = [MAJOR, MINOR, BUILD, *OTHER]
  end
end
