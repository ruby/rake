# coding: utf-8

require_relative 'gemspec_boilerplate'

spec = Gem::Specification.new do |s|

  GemspecBoilerplate.boilerplate(s)

  #s.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."

  #####Must change
  s.summary       = %q{Rake is a Make-like program implemented in ruby}
  s.description   = s.summary
  s.licenses      = %w[MIT]


  #####Unlikely to change
  s.email         = []
  s.homepage      = "https://github.com/ruby/#{s.name}.git"
  ###################################

end
