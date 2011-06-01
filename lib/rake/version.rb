module Rake
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 9,
      BUILD = 1,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
