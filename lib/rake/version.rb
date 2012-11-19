module Rake
  module Version # :nodoc: all
    NUMBERS = [
      MAJOR = 10,
      MINOR = 0,
      BUILD = 2,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
