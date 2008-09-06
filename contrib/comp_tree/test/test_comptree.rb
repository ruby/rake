
$LOAD_PATH.unshift(File.expand_path("#{File.dirname(__FILE__)}/../lib"))

require 'test/unit'
require 'benchmark'

require 'comp_tree'

srand(22)

module CompTree
  Thread.abort_on_exception = true
  HAVE_FORK = RetriableFork::HAVE_FORK
  DO_FORK = (HAVE_FORK and not ARGV.include?("--no-fork"))

  module TestCommon
    include Quix::Diagnostic

    if  ARGV.include?("--bench")
      def separator
        trace ""
        trace "-"*60
      end
    else
      def separator ; end
      def trace(*args) ; end
    end
  end

  module TestBase
    include TestCommon

    def test_1_syntax
      CompTree::Driver.new { |driver|
        driver.define(:area, :width, :height, :offset) { |width, height, offset|
          width*height - offset
        }
        
        driver.define(:width, :border) { |border|
          2 + border
        }
        
        driver.define(:height, :border) { |border|
          3 + border
        }
        
        driver.define(:border) {
          5
        }
        
        driver.define(:offset) {
          7
        }
        
        assert_equal((2 + 5)*(3 + 5) - 7,
                     driver.compute(:area, opts(6)))
      }
    end

    def test_2_syntax
      CompTree::Driver.new { |driver|
        driver.define_area(:width, :height, :offset) { |width, height, offset|
          width*height - offset
        }
        
        driver.define_width(:border) { |border|
          2 + border
        }
        
        driver.define_height(:border) { |border|
          3 + border
        }
        
        driver.define_border {
          5
        }
        
        driver.define_offset {
          7
        }
        
        assert_equal((2 + 5)*(3 + 5) - 7,
                     driver.compute(:area, opts(6)))
      }
    end

    def test_3_syntax
      CompTree::Driver.new { |driver|
        driver.define_area :width, :height, :offset, %{
          width*height - offset
        }
        
        driver.define_width :border, %{
          2 + border
        }
        
        driver.define_height :border, %{
          3 + border
        }
        
        driver.define_border %{
          5
        }
        
        driver.define_offset %{
          7
        }

        assert_equal((2 + 5)*(3 + 5) - 7,
                     driver.compute(:area, opts(6)))
      }
    end

    def test_thread_flood
      max =
        if use_fork?
          16
        else
          200
        end
      (1..max).each { |threads|
        CompTree::Driver.new { |driver|
          drain = lambda {
            1.times { }
          }
          driver.define_a(:b, &drain)
          driver.define_b(&drain)
          driver.compute(:a, opts(threads))
        }
      }
    end

    def test_malformed
      CompTree::Driver.new { |driver|
        assert_raise(CompTree::ArgumentError) {
          driver.define {
          }
        }
        assert_raise(CompTree::RedefinitionError) {
          driver.define(:a) {
          }
          driver.define(:a) {
          }
        }
        assert_raise(CompTree::ArgumentError) {
          driver.define(:b) {
          }
          driver.compute(:b, :threads => 0)
        }
        assert_raise(CompTree::ArgumentError) {
          driver.define(:c) {
          }
          driver.compute(:c, :threads => -1)
        }
      }
    end

    def generate_comp_tree(num_levels, num_children, drain_iterations)
      CompTree::Driver.new { |driver|
        root = :aaa
        last_name = root
        pick_names = lambda {
          (0..rand(num_children)).map {
            last_name = last_name.to_s.succ.to_sym
          }
        }
        drain = lambda {
          drain_iterations.times {
          }
        }
        build_tree = lambda { |parent, children, level|
          trace "building #{parent} --> #{children.join(' ')}"
          
          driver.define(parent, *children, &drain)

          if level < num_levels
            children.each { |child|
              build_tree.call(child, pick_names.call, level + 1)
            }
          else
            children.each { |child|
              driver.define(child, &drain)
            }
          end
        }
        build_tree.call(root, pick_names.call, drain_iterations)
      }
    end

    def run_generated_tree(args)
      args[:level_range].each { |num_levels|
        args[:children_range].each { |num_children|
          separator
          trace {%{num_levels}}
          trace {%{num_children}}
          trace {%{use_fork?}}
          driver = generate_comp_tree(
            num_levels,
            num_children,
            args[:drain_iterations])
          args[:thread_range].each { |threads|
            trace {%{threads}}
            2.times {
              driver.reset(:aaa)
              result = nil
              trace Benchmark.measure {
                result = driver.compute(:aaa, opts(threads))
              }
              assert_equal(result, args[:drain_iterations])
            }
          }
        }
      }
    end

    def test_generated_tree
      if use_fork?
        run_generated_tree(
          :level_range => 4..4,
          :children_range => 4..4,
          :thread_range => 8..8,
          :drain_iterations => 0)
      else
        run_generated_tree(
          :level_range => 4..4,
          :children_range => 4..4,
          :thread_range => 8..8,
          :drain_iterations => 0)
      end
    end

    def use_fork?
      not opts(0)[:fork].nil?
    end
  end
  
  module NoForkTestBase
    include TestBase
    def opts(threads)
      {
        :threads => threads,
      }
    end
  end

  module ForkTestBase
    include TestBase
    def opts(threads)
      {
        :threads => threads,
        :fork => HAVE_FORK,
      }
    end
  end
  
  class Test_1_NoFork < Test::Unit::TestCase
    include NoForkTestBase
  end

  if DO_FORK
    class Test_2_Fork < Test::Unit::TestCase
      include ForkTestBase
    end
  end

  class Test_Task < Test::Unit::TestCase
    def test_task
      CompTree::Driver.new(:discard_result => true) { |driver|
        visit = 0
        mutex = Mutex.new
        func = lambda {
          mutex.synchronize {
            visit += 1
          }
        }
        driver.define_a(:b, :c, &func)
        driver.define_b(&func)
        driver.define_c(:d, &func)
        driver.define_d(&func)

        (2..10).each { |threads|
          assert_equal(
            true,
            driver.compute(
              :a,
              :threads => threads))
          assert_equal(visit, 4)
          driver.reset(:a)
          visit = 0
        }

        (2..10).each { |threads|
          assert_equal(
            true,
            driver.compute(
              :a,
              :threads => threads,
              :fork => HAVE_FORK))
          if HAVE_FORK
            assert_equal(visit, 0)
          else
            assert_equal(visit, 4)
          end
          driver.reset(:a)
          visit = 0
        }
      }
    end
  end

  class Test_Drainer < Test::Unit::TestCase
    include TestCommon

    def drain(opts)
      code = %{ 5000.times { } }
      if opts[:fork]
        eval code
      else
        system("ruby", "-e", code)
      end
    end
    
    def run_drain(opts)
      CompTree::Driver.new { |driver|
        func = lambda {
          drain(opts)
        }
        driver.define_area(:width, :height, :offset, &func)
        driver.define_width(:border, &func)
        driver.define_height(:border, &func)
        driver.define_border(&func)
        driver.define_offset(&func)
        trace "number of threads: #{opts[:threads]}"
        trace Benchmark.measure {
          driver.compute(:area, opts)
        }
      }
    end

    def each_drain
      (1..10).each { |threads|
        yield threads
      }
    end

    def test_no_fork
      separator
      trace "Subrocess test."
      each_drain { |threads|
        run_drain({:threads => threads})
      }
    end
    
    if DO_FORK
      def test_fork
        separator
        trace "Forking test."
        each_drain { |threads|
          run_drain({:threads => threads, :fork => HAVE_FORK})
        }
      end
    end
  end
end
