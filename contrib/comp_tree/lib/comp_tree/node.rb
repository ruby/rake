
require 'rake/comp_tree/quix/diagnostic'
require 'thread'

module Rake::CompTree
  #
  # Base class for nodes in the computation tree.
  # 
  class Node
    include Quix::Diagnostic #:nodoc:

    attr_reader :name                   #:nodoc:

    attr_accessor :parents              #:nodoc:
    attr_accessor :children             #:nodoc:
    attr_accessor :function             #:nodoc:
    attr_accessor :result               #:nodoc:
    attr_accessor :shared_lock          #:nodoc:

    #
    # Create a node
    #
    def initialize(name) #:nodoc:
      @name = name
      @mutex = Mutex.new
      @children = []
      @parents = []
      reset_self
    end

    #
    # Reset the computation for this node.
    #
    def reset_self #:nodoc:
      @shared_lock = 0
      @children_results = nil
      @result = nil
    end

    #
    # Reset the computation for this node and all children.
    #
    def reset #:nodoc:
      each_downward { |node|
        node.reset_self
      }
    end

    def each_downward(&block) #:nodoc:
      block.call(self)
      @children.each { |child|
        child.each_downward(&block)
      }
    end

    def each_upward(&block) #:nodoc:
      block.call(self)
      @parents.each { |parent|
        parent.each_upward(&block)
      }
    end

    def each_child #:nodoc:
      @children.each { |child|
        yield(child)
      }
    end

    #
    # Force computation of all children; intended for
    # single-threaded mode.
    #
    def compute_now #:nodoc:
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
    def children_results #:nodoc:
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

    def trace_compute #:nodoc:
      debug {
        # --- own mutex
        trace "Computing #{@name}"
        raise Error::AssertionFailed if @result
        raise Error::AssertionFailed unless @mutex.locked?
        raise Error::AssertionFailed unless @children_results
      }
    end

    #
    # Compute this node; children must be computed and lock must be
    # already acquired.
    #
    def compute #:nodoc:
      unless defined?(@function) and @function
        raise Error::NoFunctionError,
          "No function was defined for node '#{@name.inspect}'"
      end
      @function.call(*@children_results)
    end

    def try_lock #:nodoc:
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

    def unlock #:nodoc:
      # --- shared tree mutex and own mutex
      debug {
        raise Error::AssertionFailed unless @mutex.locked?
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
      #
      # Throw away the computation result?
      #
      # This Node base class always returns false.
      #
      def discard_result?
        false
      end
    end
  end
end
