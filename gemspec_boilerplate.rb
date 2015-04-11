#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'fileutils'
require 'erb'
require_relative '.gemspec_utils'

$__DIR__ = File.expand_path(File.dirname(__FILE__))
lib = File.expand_path('lib', $__DIR__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

module GemspecBoilerplate
  module_function
  def boilerplate(s)
    #####Won't change as long as you follow conventions
    s.name           = File.basename($__DIR__)
    add_naming_metadata!(s)
    bootstrap_lib!(s)
    metadata = s.metadata

    require "#{metadata["namespaced_path"]}/version"
    spec_module         = Object.const_get(metadata["constant_name"])
    s.version        = spec_module::VERSION
    s.files         = `git ls-files -z`.split("\x0")
    s.test_files    = s.files.grep(%r{^(test|s|features)/})
    s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|s|features)/}) }
    s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
    s.require_paths = ["lib"]
    s.authors       = `git shortlog -sn`.split("\n").map {|a| a.sub(/^[\d\s]*/, '') }
  end
end

