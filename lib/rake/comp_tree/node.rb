


######################################################
# 
# **** DO NOT EDIT ****
# 
# **** THIS IS A GENERATED FILE *****
# 
######################################################



require 'rake/comptree/quix/diagnostic'
require 'thread'

module Rake::CompTree
  class Node
    include Quix::Diagnostic

    attr_reader(:name)

    attr_accessor(
      :parents,
      :children,
      :function,
      :result,
      :shared_lock)

    #
    # Create a node
    #
    def initialize(name)
      @name = name
      @mutex = Mutex.new
      @children = []
      @parents = []
      reset_self
    end

    #
    # Reset the computation for this node.
    #
    def reset_self
      @shared_lock = 0
      @children_results = nil
      @result = nil
    end

    #
    # Reset the computation for this node and all children.
    #
    def reset
      each_downward { |node|
        node.reset_self
      }
    end

    def each_downward(&block)
      block.call(self)
      @children.each { |child|
        child.each_downward(&block)
      }
    end

    def each_upward(&block)
      block.call(self)
      @parents.each { |parent|
        parent.each_upward(&block)
      }
    end

    def each_child
      @children.each { |child|
        yield(child)
      }
    end

    #
    # Force computation of all children; intended for
    # single-threaded mode.
    #
    def compute_now
      unless @children_results
        @children_results = @children.map { |child|
          child.compute_now
        }
      end
      compute
    end
    
    #
    # If all children have been computed, return their results;
    # otherwise return nil.
    #
    def children_results
      if @children_results
        @children_results
      else
        results = @children.map { |child|
          if child_result = child.result
            child_result
          else
            return nil
          end
        }
        @children_results = results
      end
    end

    def trace_compute
      debug {
        # --- own mutex
        trace "Computing #{@name}"
        raise AssertionFailed if @result
        raise AssertionFailed unless @mutex.locked?
        raise AssertionFailed unless @children_results
      }
    end

    #
    # Compute this node; children must be computed and lock must be
    # already acquired.
    #
    def compute
      @function.call(*@children_results)
    end

    def try_lock
      # --- shared tree mutex and own mutex
      if @shared_lock == 0 and @mutex.try_lock
        trace "Locking #{@name}"
        each_upward { |node|
          node.shared_lock += 1
          trace "#{node.name} locked by #{@name}: level: #{node.shared_lock}"
        }
        true
      else
        false
      end
    end

    def unlock
      # --- shared tree mutex and own mutex
      debug {
        raise AssertionFailed unless @mutex.locked?
        trace "Unlocking #{@name}"
      }
      each_upward { |node|
        node.shared_lock -= 1
        debug {
          if node.shared_lock == 0
            trace "#{node.name} unlocked by #{@name}"
          end
        }
      }
      @mutex.unlock
    end

    class << self
      def discard_result?
        false
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


