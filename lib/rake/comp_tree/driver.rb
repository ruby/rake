
require 'rake/comp_tree/diagnostic'
require 'rake/comp_tree/algorithm'
require 'rake/comp_tree/node'
require 'rake/comp_tree/error'

require 'thread'

module Rake end
module Rake::CompTree
  #
  # Driver is the main interface to the computation tree.  It is
  # responsible for defining nodes and running computations.
  #
  class Driver
    include Diagnostic
    include Algorithm
    
    #
    # Begin a new computation tree.
    #
    # Options hash:
    #
    # <tt>:node_class</tt> -- (Class) CompTree::Node subclass from
    # which nodes are created.
    #
    def initialize(opts = nil)
      @node_class =
        if opts and opts[:node_class]
          opts[:node_class]
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
    # The method_missing form:
    #  driver.define_area(:width, :height, :offset) { |width, height, offset|
    #    width*height - offset
    #  }
    #
    # The eval form:
    #  driver.define_area :width, :height, :offset, %{
    #    width*height - offset
    #  }
    # (Note the '%' before the brace.)
    #
    # The raw form:
    #  driver.define(:area, :width, :height, :offset) { |width, height, offset|
    #    width*height - offset
    #  }
    #
    def define(*args, &block)
      parent_name = args.first
      children_names = args[1..-1]
      
      unless parent_name
        raise Error::ArgumentError, "No name given for node"
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
        raise Error::RedefinitionError, "Node #{parent.name} already defined."
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
    # Mark this node and all its children as uncomputed.
    #
    # Arguments:
    #
    # +name+ -- (Symbol) node name.
    #
    def reset(name)
      @nodes[name].reset
    end

    #
    # Check for a cyclic graph below the given node.  Raises
    # CompTree::Error::CircularError if found.
    #
    # Arguments:
    #
    # +name+ -- (Symbol) node name.
    #
    def check_circular(name)
      helper = lambda { |root, chain|
        if chain.include? root
          raise Error::CircularError,
            "Circular dependency detected: #{root} => #{chain.last} => #{root}"
        end
        @nodes[root].children.each { |child|
          helper.call(child.name, chain + [root])
        }
      }
      helper.call(name, [])
    end

    #
    # Compute this node.
    #
    # Arguments:
    #
    # +name+ -- (Symbol) node name.
    #
    # +threads+ -- (Integer) number of threads.
    #
    def compute(name, threads)
      root = @nodes[name]

      if threads < 1
        raise Error::ArgumentError, "threads is #{threads}"
      end

      if threads == 1
        root.result = root.compute_now
      else
        compute_multithreaded(root, threads)
      end
    end
  end
end
