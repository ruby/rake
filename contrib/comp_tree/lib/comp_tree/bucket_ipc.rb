
require 'drb'
require 'thread'

require 'comp_tree/retriable_fork'
require 'comp_tree/quix/diagnostic'
require 'comp_tree/quix/builtin/kernel/tap'

module CompTree
  module BucketIPC
    class Bucket
      include Quix::Diagnostic
      include RetriableFork

      def initialize(address, timeout, wait_interval)
        trace "Making bucket with address #{address}"
        
        @remote_pid = fork {
          own_object = Class.new {
            attr_accessor(:contents)
          }.new
          server = DRb.start_service(address, own_object)
          debug {
            server.verbose = true
          }
          DRb.thread.join
        }

        @remote_object = DRbObject.new_with_uri(address)
        @address = address
        @timeout = timeout
        @wait_interval = wait_interval
      end
      
      attr_accessor(:timeout, :wait_interval)
      attr_reader(:address)
      
      def contents=(new_contents)
        connect {
          @remote_object.contents = new_contents
        }
      end
      
      def contents
        connect {
          @remote_object.contents
        }
      end
      
      def stop
        Process.kill("TERM", @remote_pid)
      end
      
      private
      
      def connect
        begin
          return yield
        rescue DRb::DRbConnError
          start = Time.now
          begin
            Kernel.sleep(@wait_interval)
            return yield
          rescue DRb::DRbConnError
            if Time.now - start > @timeout
              raise
            end
            retry
          end
        end
      end
    end

    class DriverBase
      def initialize(addresses, timeout, wait_interval)
        begin
          @buckets = addresses.map { |address|
            Bucket.new(address, timeout, wait_interval)
          }
          if block_given?
            yield @buckets
          end
        ensure
          if block_given?
            stop
          end
        end
      end
      
      def stop
        if defined?(@buckets)
          @buckets.each { |bucket|
            bucket.stop
          }
        end
      end
    end

    class Driver < DriverBase
      DEFAULTS = {
        :timeout => 0.5,
        :wait_interval => 0.05,
        :port_start => 18181,
      }

      module BucketCounter
        @mutex = Mutex.new
        @count = 0
        class << self
          def increment_count
            @mutex.synchronize {
              @count += 1
            }
          end

          def map_indexes(num_buckets)
            Array.new.tap { |result|
              num_buckets.times {
                result << yield(increment_count)
              }
            }
          end
        end
      end

      def initialize(num_buckets, opts_in = {})
        opts = DEFAULTS.merge(opts_in)

        addresses = 
          if RetriableFork::HAVE_FORK
            #
            # Assume the existence of fork implies a unix machine.
            #
            require 'drb/unix'
            basename = "drbunix://#{Dir.tmpdir}/bucket.#{Process.pid}.#{rand}"
            BucketCounter.map_indexes(num_buckets) { |index|
              "#{basename}.#{index}"
            }
          else
            #
            # Fallback: use the default socket.
            #
            BucketCounter.map_indexes(num_buckets) { |index|
              "druby://localhost:#{opts[:port_start] + index}"
            }
          end
        super(addresses, opts[:timeout], opts[:wait_interval])
      end
    end
  end
end
