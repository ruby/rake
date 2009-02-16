
require 'comp_tree'

def use_fork?
  CompTree::RetriableFork::HAVE_FORK and ARGV.include?("--use-fork")
end

if use_fork?
  puts "Testing with fork."
end
