
module Rake end
module Rake::CompTree
  module Error
    # Base class for CompTree errors.
    class Base < StandardError ; end
    
    # Internal error inside CompTree.  Please send a bug report.
    class AssertionFailed < Base ; end
    
    # Bad arguments were passed to a method.
    class ArgumentError < Base ; end
    
    #
    # Attempt to redefine a Node.
    #
    # If you wish to only replace the function, set
    #   driver.nodes[name].function = some_new_lambda
    #
    class RedefinitionError < Base ; end
    
    # A Cyclic graph was detected.
    class CircularError < Base ; end

    # No function was defined for this node.
    class NoFunctionError < Base ; end
  end
end
