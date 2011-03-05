module Rake
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 9,
      BUILD = 0,
      BETA  = 'beta',
      BETANUM = 2,
    ]
  end
  VERSION = Version::NUMBERS.join('.')
end
