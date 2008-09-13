
require 'quix/kernel'
require 'quix/thread_local'
require 'quix/builtin/kernel/tap'
require 'ostruct'

module CompTree
  module Vars
    include CompTree::Misc

    def eval_locals(code_with_locals, &block)
      code_with_locals.call.split(",").map { |name|
        # trim
        name.sub(%r!\A\s+!, "").sub(%r!\s+\Z!, "")
      }.each { |name|
        block.call(name, eval(name, code_with_locals.binding))
      }
    end

    def hash_to_locals(&block)
      if hash = block.call
        hash.each_pair { |name, value|
          Vars.argument_cache.value = value
          eval("#{name} = #{Vars.name}.argument_cache.value", block.binding)
        }
      end
    end

    def locals_to_hash(&block)
      Hash.new.tap { |hash|
        eval_locals(block) { |name, value|
          hash[name.to_sym] = value
        }
      }
    end

    def config_to_hash(code)
      Hash.new.tap { |hash|
        each_config_pair(code) { |name, value|
          hash[name] = value
        }
      }
    end
    
    def each_config_pair(code, &block)
      Vars.argument_cache.value = code
      vars, bind = private__eval_config_code
      vars.each { |var|
        yield(var.to_sym, eval(var, bind))
      }
    end

    def hash_to_ivs(opts = nil, &block)
      if hash = block.call
        private__hash_to_ivs(
          hash,
          eval("self", block.binding),
          opts && opts[:force])
      end
    end

    def locals_to_ivs(opts = nil, &block)
      hash = Hash.new
      eval_locals(block) { |name, value|
        hash[name] = value
      }
      private__hash_to_ivs(
        hash,
        eval("self", block.binding), 
        opts && opts[:force])
    end

    def with_readers(hash, *args, &block)
      caller_self = eval("self", block.binding)
      readers =
        if args.empty?
          hash.keys
        else
          args
        end
      singleton_class.instance_eval {
        added = Array.new
        begin
          readers.each { |reader|
            if caller_self.respond_to?(reader)
              raise(
                "Reader '#{reader}' already exists in #{caller_self.inspect}")
            end
            define_method(reader) {
              hash[reader]
            }
            added << reader
          }
          block.call
        ensure
          added.each { |reader|
            remove_method(reader)
          }
        end
      }
    end

    private

    class << self
      attr_accessor :argument_cache
    end
    @argument_cache = ThreadLocal.new

    def private__eval_config_code
      eval %Q{
        #{Vars.argument_cache.value}

        [local_variables, binding]
      }
    end

    def private__hash_to_ivs(hash, target, force)
      target.instance_eval {
        hash.each_pair { |name, value|
          ivar = "@#{name}"
          unless force
            existing_value = no_warnings {
              instance_variable_get(ivar)
            }
            unless existing_value.nil?
              raise "instance variable already set: #{name}"
            end
          end
          instance_variable_set(ivar, value)
        }
      }
    end

    extend self
  end
end

