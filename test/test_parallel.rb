
require 'rbconfig'
require 'test/unit'

PARALLEL_TEST_MESSAGE = <<'EOS'


Task graph for sample parallel execution:

                default
                  / \
                 /   \
                a     b
               / \
              /   \
             x     y

EOS
      
if Rake.application.num_threads > 1
  class TestSimpleParallel < Test::Unit::TestCase
    def setup
      puts PARALLEL_TEST_MESSAGE
    end

    def test_parallel
      here = File.dirname(__FILE__)
      rake = File.expand_path("#{here}/../bin/rake")

      ENV["RUBYLIB"] = lambda {
        lib = File.expand_path("#{here}/../lib")
        current = ENV["RUBYLIB"]
        sep = Rake.application.windows? ? ";" : ":"
        if current
          "#{lib}#{sep}#{current}"
        else
          lib
        end
      }.call

      [
       ["Rakefile.simple", true],
       ["Rakefile.seq", false],
      ].each { |file, disp|
        (1..5).each { |n|
          args = [rake, "--threads", n.to_s, "-s", "-f", "test/#{file}"]
          if disp
            puts "\nvisual check: #{n} thread#{n > 1 ? 's' : ''}"
            puts args.join(" ")
          end
          assert(ruby(*args))
        }
      }
    end
  end
end
