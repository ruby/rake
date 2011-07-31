module Rake
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 9,
      BUILD = 2,
      DRAKE_MAJOR = 0,
      DRAKE_MINOR = 3,
      DRAKE_BUILD = 1,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
