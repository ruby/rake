
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
    include Algorithm

    #
    # Build and run a new computation tree.
    #
    # Options hash:
    #
    # <tt>:node_class</tt> -- (Class) CompTree::Node subclass from
    # which nodes are created.
    #
    def initialize(opts = nil)
      @node_class = (
        if opts and opts[:node_class]
          opts[:node_class]
        else
          Node
        end
      )
      @nodes = Hash.new
    end

    #
    # Name-to-node hash.
    #
    attr_reader :nodes

    #
    # Define a computation node.
    #
    # The first argument is the name of the node to define.
    # Subsequent arguments are the names of this node's children.
    #
    # The values of the child nodes are passed to the block.  The
    # block returns the result of this node.
    #
    # In this example, a computation node named +area+ is defined
    # which depends on the nodes +width+ and +height+.
    #
    #   driver.define(:area, :width, :height) { |width, height|
    #     width*height
    #   }
    #
    # NOTE: You must return a non-nil value to signal the computation
    # is complete.  If nil is returned, the node will be recomputed.
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
      parent = @nodes[parent_name] || (
        @nodes[parent_name] = @node_class.new(parent_name)
      )

      if parent.function
        raise RedefinitionError, "Node `#{parent.name.inspect}' redefined."
      end
      parent.function = block
      
      children = children_names.map { |child_name|
        @nodes[child_name] || (
          @nodes[child_name] = @node_class.new(child_name)
        )
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
    # Mark this node and all its children as uncomputed.
    #
    # Arguments:
    #
    # +name+ -- unique node identifier (usually a symbol).
    #
    def reset(name)
      @nodes[name].reset
    end

    #
    # Check for a cyclic graph below the given node.  If found,
    # returns the names of the nodes (in order) which form a loop.
    # Otherwise returns nil.
    #
    # Arguments:
    #
    # +name+ -- unique node identifier (usually a symbol).
    #
    def check_circular(name)
      helper = Proc.new { |root, chain|
        if chain.include? root
          return chain + [root]
        end
        @nodes[root].children.each { |child|
          helper.call(child.name, chain + [root])
        }
      }
      helper.call(name, [])
      nil
    end

    #
    # Compute this node.
    #
    # Arguments:
    #
    # +name+ -- unique node identifier (usually a symbol).
    #
    # +threads+ -- (Integer) number of threads.
    #
    # compute(:volume, :threads => 4) syntax is also accepted.
    #
    def compute(name, opts)
      threads = (opts.respond_to?(:to_i) ? opts : opts[:threads]).to_i
      root = @nodes[name]

      if threads < 1
        raise ArgumentError, "threads is #{threads}"
      end

      root.result or (
        if threads == 1
          root.result = root.compute_now
        else
          compute_multithreaded(root, threads)
        end
      )
    end
  end
end
