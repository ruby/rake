


######################################################
# 
# **** DO NOT EDIT ****
# 
# **** THIS IS A GENERATED FILE *****
# 
######################################################



module Rake::CompTree
  #
  # A TaskNode is a Node which discards its results
  #
  class TaskNode < Node
    def compute
      @function.call
      true
    end

    class << self
      def discard_result?
        true
      end
    end
  end
end




######################################################
# 
# **** DO NOT EDIT ****
# 
# **** THIS IS A GENERATED FILE *****
# 
######################################################


