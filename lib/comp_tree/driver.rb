
require 'comp_tree/bucket_ipc'
require 'comp_tree/quix/diagnostic'
require 'comp_tree/quix/kernel'
require 'comp_tree/algorithm'
require 'comp_tree/node'
require 'comp_tree/task_node'
require 'comp_tree/error'

require 'thread'

#
# Computation Tree module.
#
module CompTree
  #
  # The Driver is the main interface to the computation tree, as it is
  # responsible for defining nodes and performing computations.
  #
  class Driver
    DEFAULTS = {
      :threads => 1,
      :fork => false,
      :timeout => 5.0,
      :wait_interval => 0.02,
    }

    include Quix::Diagnostic #!:nodoc:
    include Quix::Kernel #!:nodoc:
    
    #
    # Begin a new computation tree.
    #
    # Options:
    #
    # <tt>:node_class</tt> -- (Class) CompTree::Node subclass from
    # which nodes are created.
    #
    # <tt>:discard_result</tt> -- (boolean) You are <em>not</em>
    # interested in the final answer, but only in the actions which
    # complete the computation.  This is equivalent to saying
    # <tt>:node_class => CompTree::TaskNode</tt>.  (If you are forking
    # processes, it is good to know that IPC is not needed to
    # communicate the result.)
    #
    def initialize(opts = nil)
      if opts and opts[:node_class] and opts[:discard_result]
        raise(
          ArgumentError,
          "#{self.class.name}.new: :discard_result and :node_class " +
          "are mutually exclusive")
      end

      @node_class =
        if opts and opts[:node_class]
          opts[:node_class]
        elsif opts and opts[:discard_result]
          TaskNode
        else
          Node
        end

      @nodes = Hash.new

      if block_given?
        yield self
      end
    end

    #
    # Name-to-node hash.
    #
    attr_reader :nodes

    #
    # Define a computation node.
    #
    # There are three distinct forms of a node definition.  In each of
    # the following examples, a computation node named +area+ is
    # defined which depends on the nodes +height+, +width+, +offset+.
    #
    # The +method_missing+ form:
    #  driver.define_area(:width, :height, :offset) { |width, height, offset|
    #    width*height - offset
    #  }
    #
    # The +eval+ form:
    #  driver.define_area :width, :height, :offset, %{
    #    width*height - offset
    #  }
    # Note the '%' before the brace.  The +eval+ form creates a lambda for you.
    #
    # The raw form:
    #   driver.define_area(:width, :height, :offset) { |width, height, offset|
    #     width*height - offset
    #   }
    #
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

    #
    # parsing/evaling helper
    #
    def evaling_define(*args) #:nodoc:
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

    def method_missing(symbol, *args, &block) #:nodoc:
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

    #
    # Mark as uncomputed the node called +name+.
    #
    def reset(name)
      @nodes[name].reset
    end

    #
    # Check for a cyclic graph.  Raises CompTree::CircularError if
    # found.
    #
    def check_circular(root)
      helper = lambda { |name, chain|
        if chain.include? name
          raise CircularError,
            "Circular dependency detected: #{name} => #{chain.last} => #{name}"
        end
        @nodes[name].children.each { |child|
          helper.call(child.name, chain + [name])
        }
      }
      helper.call(root, [])
    end

    #
    # Compute a node.
    #
    # Options:
    #
    # <tt>:threads</tt> -- (Integer) Number of parallel threads.
    #
    # <tt>:fork</tt> -- (boolean) Whether to fork each computation
    # node into its own process.
    #
    # <tt>:wait_interval</tt> -- (seconds) (Obscure) How long to
    # wait after an IPC failure.
    #
    # <tt>:timeout</tt> -- (seconds) (Obscure) Give up after this
    # period of IPC failures.
    #
    # Defaults options are taken from Driver::DEFAULTS.
    #
    def compute(name, opts = nil)
      abort_on_exception {
        compute_private(name, opts || Hash.new)
      }
    end

    private
    
    def compute_private(name, opts_in)
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
        # Multithreaded computation without fork.
        #
        Algorithm.compute_multithreaded(
          root, opts[:threads], opts[:fork], nil)
      end
    end
  end
end
