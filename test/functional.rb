#!/usr/bin/env ruby

begin
  require 'rubygems'
  gem 'session'
  require 'session'
  puts 'OK!'
rescue LoadError
  puts "UNABLE TO RUN FUNCTIONAL TESTS"
  puts "No Session Found"
end

if defined?(Session)
  puts "RUNNING SESSIONS"
  puts $:
  require 'test/session_functional'
end
