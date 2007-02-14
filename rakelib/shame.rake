#!/usr/bin/env ruby
# -*- ruby -*-

begin
  require 'rbosax'
  require 'code_statistics'
  
  desc "Publish Code/Test Ratio on iChat"
  task :shame do
    stats = CodeStatistics.new(['Rake', 'lib'], ['Unit tests', 'test'])
    code  = stats.send :calculate_code
    tests = stats.send :calculate_tests
    ichat = OSA.app('ichat')
    msg = "Rake Code To Test Ratio: 1:#{sprintf("%.1f", tests.to_f/code)}" 
    ichat.status_message = msg
    $stderr.puts %|iChat status set to: #{msg.inspect}|
  end
rescue LoadError
end

