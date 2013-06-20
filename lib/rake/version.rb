module Rake
  VERSION = '10.1.1.beta.1'

  module Version # :nodoc: all
    MAJOR, MINOR, BUILD, *OTHER = Rake::VERSION.split '.'

    NUMBERS = [MAJOR, MINOR, BUILD, *OTHER]
  end
end
