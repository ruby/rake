#!/usr/bin/env ruby

begin
  require 'rubygems'
  gem 'session'
  require 'session'
rescue LoadError
  if File::ALT_SEPARATOR
    puts "Unable to run functional tests on MS Windows. Skipping."
  else
    puts "Unable to run functional tests -- please run \"gem install session\""
  end
end

if defined?(Session)
  if File::ALT_SEPARATOR
    puts "Unable to run functional tests on MS Windows. Skipping."
  else
    require 'test/functional/session_based_tests.rb'
  end
end
