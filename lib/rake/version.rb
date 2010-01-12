module Rake
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 8,
      BUILD = 99,
      BETA  = 5,
      DRAKE_MAJOR = 3,
      DRAKE_MINOR = 0,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
