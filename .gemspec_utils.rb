#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'yaml'
require 'erb'

module GemspecBoilerplate
  module_function
  def camelize(string, uppercase_first_letter = true)
    string = string.to_s
    if uppercase_first_letter
      string = string.sub(/^[a-z\d]*/) { $&.capitalize }
    else
      string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
    end
    string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
    string.gsub!(/\//, '::')
    string
  end

  def add_naming_metadata!(spec)
    metadata = spec.metadata
    metadata.merge!({
      "name" => spec.name,
      "underscored_name" => spec.name.tr('-', '_'),
      "namespaced_path"  => spec.name.tr('-', '/')

    })
    metadata["constant_name"] = camelize(metadata["namespaced_path"])
  end

  def templates
    return @templates if @templates
    File.open(__FILE__) do |this_file|
      this_file.find { |line| line =~ /^__END__ *$/ }
      @templates = YAML.load(this_file.read)
    end
    @templates
  end

  def template_write(filename, config, template_str)
    File.write(filename, ERB.new(template_str, nil,'-').result(binding))
  end

  def bootstrap_lib!(spec)
    m = spec.metadata
    namespaced_path = m["namespaced_path"]
    versionfile = "lib/#{namespaced_path}/version.rb"
    rbfile = "lib/#{namespaced_path}.rb"
    FileUtils.mkdir_p File.dirname(versionfile)
    config = m.dup
    config["constant_array"] = m["constant_name"].split("::")

    template_write(rbfile, config, templates["newgem.tt"])  unless File.exist?(rbfile)
    template_write(versionfile, config, templates["version.rb.tt"])  unless File.exist?(versionfile)
  end
end

__END__
---
newgem.tt: |
  require "<%=config["namespaced_path"]%>/version"
  <%- if config[:ext] -%>
  require "<%=config["namespaced_path"]%>/<%=config[:underscored_name]%>"
  <%- end -%>

  <%- config["constant_array"].each_with_index do |c,i| -%>
  <%= '  '*i %>module <%= c %>
  <%- end -%>
  <%= '  '*config["constant_array"].size %>
  <%- (config["constant_array"].size-1).downto(0) do |i| -%>
  <%= '  '*i %>end
  <%- end -%>
version.rb.tt: |
  <%- config["constant_array"].each_with_index do |c,i| -%>
  <%= '  '*i %>module <%= c %>
  <%- end -%>
  <%= '  '*config["constant_array"].size %>VERSION = "0.1.0"
  <%- (config["constant_array"].size-1).downto(0) do |i| -%>
  <%= '  '*i %>end
  <%- end -%>
