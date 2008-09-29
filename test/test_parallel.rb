
require 'rbconfig'
require 'test/unit'

if Rake.application.num_threads > 1
  class TestSimpleParallel < Test::Unit::TestCase
    def test_1
      here = File.dirname(__FILE__)
      rake = File.expand_path("#{here}/../bin/rake")

      ENV["RUBYLIB"] = lambda {
        lib = File.expand_path("#{here}/../lib")
        current = ENV["RUBYLIB"]
        if current
          "#{lib}:#{current}"
        else
          lib
        end
      }.call
      
      Dir.chdir(here) {
        [
         "Rakefile.simple",
         "Rakefile.seq",
        ].each { |file|
          (1..5).each { |n|
            args = [rake, "--threads", n.to_s, "-f", file]
            puts("\n" + "-"*40)
            puts(args.join(" "))
            assert(system(*args))
          }
        }
      }
    end
  end
end
