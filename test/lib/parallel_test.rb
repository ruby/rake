
require 'rbconfig'
require 'test/unit'
require 'rake'
require 'test/rake_test_setup'

if Rake.application.options.threads != 1
  class TestParallel < Test::Unit::TestCase
    VISUALS = false
    TIME_STEP = 0.25
    TIME_EPSILON = 0.05
    MAX_THREADS = 5

    def trace(str)
      if VISUALS
        puts str
      end
    end

    def assert_order(expected, actual)
      assert_in_delta(expected*TIME_STEP, actual, TIME_EPSILON)
    end

    def teardown
      Rake::Task.clear
    end

    def test_parallel
      trace GRAPH

      data = Hash.new { |hash, key| hash[key] = Hash.new }
      
      (0..MAX_THREADS).each { |threads|
        app = Rake::Application.new
        app.options.threads = threads

        app.define_task Rake::Task, :default => [:a, :b]
        app.define_task Rake::Task, :a => [:x, :y]
        app.define_task Rake::Task, :b

        mutex = Mutex.new
        STDOUT.sync = true
        start_time = nil

        %w[default a b x y].each { |task_name|
          app.define_task Rake::Task, task_name.to_sym do
            mutex.synchronize {
              trace "task #{task_name}"
              data[threads][task_name] = Time.now - start_time
            }
            sleep(TIME_STEP)
          end
        }
      
        trace "-"*50
        trace "threads: #{threads}"
        start_time = Time.now
        app[:default].invoke
      }

      assert_order(0, data[1]["x"])
      assert_order(1, data[1]["y"])
      assert_order(2, data[1]["a"])
      assert_order(3, data[1]["b"])
      assert_order(4, data[1]["default"])

      assert_order(0, data[2]["x"])
      assert_order(0, data[2]["y"])
      assert_order(1, data[2]["a"])
      assert_order(1, data[2]["b"])
      assert_order(2, data[2]["default"])

      ([0] + (3..MAX_THREADS).to_a).each { |threads|
        assert_order(0, data[threads]["x"])
        assert_order(0, data[threads]["y"])
        assert_order(0, data[threads]["b"])
        assert_order(1, data[threads]["a"])
        assert_order(2, data[threads]["default"])
      }
    end 

    def test_invoke_inside_invoke
      assert_raises(Rake::InvokeInsideInvoke) {
        app = Rake::Application.new
        app.options.threads = 4
        app.define_task Rake::Task, :root do
          app[:stuff].invoke
        end
        app.define_task Rake::Task, :stuff do
          flunk
        end
        app[:root].invoke
      }
    end
    
    def test_randomize
      size = 100
      [false, true].each do |randomize|
        memo = ThreadSafeArray.new
        app = Rake::Application.new
        app.define_task Rake::Task, :root
        size.times { |n|
          app.define_task Rake::Task, :root => n.to_s
          app.define_task Rake::Task, n.to_s do
            memo << n
          end
        }
        app.options.randomize = randomize
        app[:root].invoke
        numbers = (0...size).to_a
        if randomize
          assert_not_equal(numbers, memo)
        else
          assert_equal(numbers, memo)
        end
      end
    end

    def test_multitask_not_called
      # ensure MultiTask methods are not called by hijacking all of them

      originals = [
       :private_instance_methods,
       :protected_instance_methods, 
       :public_instance_methods,
      ].inject(Hash.new) { |acc, query|
        result = Rake::MultiTask.send(query, false).inject(Hash.new) {
          |sub_acc, method_name|
          sub_acc.merge!(
            method_name => Rake::MultiTask.instance_method(method_name)
          )
        }
        acc.merge!(result)
      }

      memo = ThreadSafeArray.new

      Rake::MultiTask.module_eval {
        originals.each_pair { |method_name, method_object|
          remove_method method_name
          define_method method_name do |*args|
            # missing |&block| due to 1.8.6, but not using it anyway
            memo << 'called'
            method_object.bind(self).call(*args)
          end
        }
      }

      begin
        app = Rake::Application.new

        define = lambda {
          app.define_task Rake::Task, task(:x) { }
          app.define_task Rake::Task, task(:y) { }
          app.define_task Rake::MultiTask, :root => [:x, :y]
        }

        app.options.threads = 1
        define.call
        app[:root].invoke
        assert_equal ['called'], memo

        app.clear
        memo.clear
        assert_raises(RuntimeError) { app[:root].invoke }
        
        app.options.threads = 4
        define.call
        app[:root].invoke
        assert_equal [], memo
      ensure
        Rake::MultiTask.module_eval {
          originals.each_pair { |method_name, method_object|
            remove_method method_name
            define_method method_name, method_object
          }
        }
      end
    end

    GRAPH = <<-'EOS'

    Task graph for sample parallel execution:
  
                  default
                    / \
                   /   \
                  a     b
                 / \
                /   \
               x     y
  
    EOS
  end
end
