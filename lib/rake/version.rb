module Rake
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 9,
      BUILD = 0,
      DRAKE_MAJOR = 0,
      DRAKE_MINOR = 3,
      DRAKE_BUILD = 0,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
