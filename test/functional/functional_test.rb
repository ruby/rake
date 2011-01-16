#!/usr/bin/env ruby

begin
  require 'rubygems'
  gem 'session'
  require 'session'
rescue LoadError
  puts "Unable to run functional tests -- please run \"gem install session\""
end

if defined?(Session)
  require 'test/functional/session_based_tests.rb'
end
