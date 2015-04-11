module Rake

  VERSION = '10.4.2'

  module Version # :nodoc: all
    MAJOR, MINOR, BUILD, *OTHER = Rake::VERSION.split '.'

    NUMBERS = [MAJOR, MINOR, BUILD, *OTHER]
  end
end
