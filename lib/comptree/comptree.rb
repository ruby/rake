
require 'comptree/bucket_ipc'
require 'comptree/quix/diagnostic'
require 'comptree/algorithm'
require 'thread'

module CompTree
  class Error < StandardError ; end
  class AssertionFailed < Error ; end
  class ArgumentError < Error ; end
  class RedefinitionError < Error ; end

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

  class Driver
    DEFAULTS = {
      :threads => 1,
      :fork => false,
      :timeout => 5.0,
      :wait_interval => 0.02,
    }

    include Quix::Diagnostic

    attr_reader :nodes
    
    def initialize(opts = nil)
      @node_class =
        if opts
          if t = opts[:node_class]
            t
          elsif opts[:discard_result]
            if opts[:node_class]
              raise(
                ArgumentError,
                "#{self.class.name}.new: :discard_result and :node_class " +
                "are mutually exclusive")
            end
            TaskNode
          end
        else
          Node
        end
      @nodes = Hash.new
      if block_given?
        yield self
      end
    end

    def define(*args, &block)
      parent_name = args.first
      children_names = args[1..-1]
      
      unless parent_name
        raise ArgumentError, "No name given for node"
      end
      
      #
      # retrieve or create parent and children
      #
      parent =
        if t = @nodes[parent_name]
          t
        else 
          @nodes[parent_name] = @node_class.new(parent_name)
        end

      if parent.function
        raise RedefinitionError, "Node #{parent.name} already defined."
      end
      parent.function = block
      
      children = children_names.map { |child_name|
        if t = @nodes[child_name]
          t
        else
          @nodes[child_name] = @node_class.new(child_name)
        end
      }

      #
      # link
      #
      parent.children = children
      children.each { |child|
        child.parents << parent
      }
    end

    def evaling_define(*args)
      function_name = args[0]
      function_arg_names = args[1..-2]
      function_string = args.last.to_str
      
      comma_separated = function_arg_names.map { |name|
        name.to_s
      }.join(",")

      eval_me = %{ 
        lambda { |#{comma_separated}|
          #{function_string}
        }
      }

      function = eval(eval_me, TOPLEVEL_BINDING)

      define(function_name, *function_arg_names, &function)
    end

    def method_missing(symbol, *args, &block)
      if match = symbol.to_s.match(%r!\Adefine_(\w+)\Z!)
        method_name = match.captures.first.to_sym
        if block
          define(method_name, *args, &block)
        else
          evaling_define(method_name, *args)
        end
      else
        super(symbol, *args, &block)
      end
    end

    def reset(name)
      @nodes[name].reset
    end
    
    def compute(name, opts_in = {})
      opts = DEFAULTS.merge(opts_in)
      root = @nodes[name]

      if opts[:threads] < 1
        raise ArgumentError, "threads is #{opts[:threads]}"
      end

      if opts[:threads] == 1
        root.result = root.compute_now
      elsif opts[:fork] and not @node_class.discard_result?
        #
        # Use buckets to send results across forks.
        #
        result = nil
        BucketIPC::Driver.new(opts[:threads], opts) { |buckets|
          result =
            Algorithm.compute_multithreaded(
              root, opts[:threads], opts[:fork], buckets)
        }
        result
      else
        #
        # Non-forked multithreaded computation.
        #
        Algorithm.compute_multithreaded(
          root, opts[:threads], opts[:fork], nil)
      end
    end
  end
end
