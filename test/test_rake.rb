
require 'rbconfig'

here = File.dirname(__FILE__)

rake =
  if Config::CONFIG["arch"] =~ %r!java!i
    "jrake"
  else
    "rake"
  end

ENV["RUBYLIB"] = lambda {
  lib = File.expand_path("#{here}/../lib")
  current = ENV["RUBYLIB"]
  if current
    "#{current}:#{lib}"
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
      args = [rake, "-rcomptree", n.to_s, "-f", file]
      puts("-"*40)
      puts(args.join(" "))
      unless system(*args)
        raise "rake failed"
      end
    }
  }
}
