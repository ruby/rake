
module CompTree
  #
  # TaskNode is a Node which discards its results
  #
  class TaskNode < Node
    def compute #:nodoc:
      @function.call
      true
    end

    class << self
      #
      # TaskNode always returns true.
      #
      def discard_result?
        true
      end
    end
  end
end

