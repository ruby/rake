module Rake
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 8,
      BUILD = 99,
      BETA  = 5,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
