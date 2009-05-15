#!/usr/bin/env ruby

begin
  require 'rubygems'
  gem 'session'
  require 'session'
rescue LoadError
  puts "UNABLE TO RUN FUNCTIONAL TESTS"
  puts "No Session Found (gem install session)"
end

if defined?(Session)
  puts "RUNNING WITH SESSIONS"
  require 'test/functional/session_based_tests.rb'
end
