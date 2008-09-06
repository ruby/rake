
module CompTree
  module Error
    # Base class for CompTree errors.
    class Base < StandardError ; end
    
    # Internal error inside CompTree.
    class AssertionFailed < Base ; end
    
    # Encountered bad arguments to a method.
    class ArgumentError < Base ; end
    
    # Node was already defined.
    class RedefinitionError < Base ; end
    
    # A Cyclic graph was detected.
    class CircularError < Base ; end
  end
end
