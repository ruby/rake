module Rake
  module Version # :nodoc: all
    NUMBERS = [
      MAJOR = 0,
      MINOR = 9,
      BUILD = 5,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
