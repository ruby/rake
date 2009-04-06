
module Rake end
module Rake::CompTree
  # Base class for CompTree errors.
  class Error < StandardError ; end
    
  # Internal error inside CompTree.  Please send a bug report.
  class AssertionFailedError < Error ; end
  
  # Bad arguments were passed to a method.
  class ArgumentError < Error ; end
  
  #
  # Attempt to redefine a Node.
  #
  # If you wish to only replace the function, set
  #   driver.nodes[name].function = some_new_lambda
  #
  class RedefinitionError < Error ; end
  
  # No function was defined for this node.
  class NoFunctionError < Error ; end
end
