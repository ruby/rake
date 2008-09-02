


######################################################
# 
# **** DO NOT EDIT ****
# 
# **** THIS IS A GENERATED FILE *****
# 
######################################################



require 'rake/comptree/bucket_ipc'
require 'rake/comptree/quix/diagnostic'
require 'rake/comptree/quix/kernel'
require 'rake/comptree/algorithm'
require 'rake/comptree/node'
require 'rake/comptree/task_node'
require 'rake/comptree/error'

require 'thread'

module Rake::CompTree
  class Driver
    DEFAULTS = {
      :threads => 1,
      :fork => false,
      :timeout => 5.0,
      :wait_interval => 0.02,
    }

    include Quix::Diagnostic
    include Quix::Kernel

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

    attr_reader :nodes

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

    def node(name)
      @nodes[name]
    end

    def compute(name, opts = {})
      abort_on_exception {
        compute_private(name, opts)
      }
    end

    def node(name)
      @nodes[name]
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



######################################################
# 
# **** DO NOT EDIT ****
# 
# **** THIS IS A GENERATED FILE *****
# 
######################################################


