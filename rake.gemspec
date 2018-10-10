# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rake/version"

Gem::Specification.new do |s|
  s.name = "rake".freeze
  s.version = Rake::VERSION
  s.authors = ["Hiroshi SHIBATA", "Eric Hodel", "Jim Weirich"].map(&:freeze)
  s.email = ["hsbt@ruby-lang.org", "drbrain@segment7.net", ""].map(&:freeze)

  s.summary = "Rake is a Make-like program implemented in Ruby".freeze
  s.description = <<-DESCRIPTION.gsub(%r{^\s{4}}, "")
    Rake is a Make-like program implemented in Ruby. Tasks and dependencies are
    specified in standard Ruby syntax.
    Rake has the following features:
      * Rakefiles (rake's version of Makefiles) are completely defined in standard Ruby syntax.
        No XML files to edit. No quirky Makefile syntax to worry about (is that a tab or a space?)
      * Users can specify tasks with prerequisites.
      * Rake supports rule patterns to synthesize implicit tasks.
      * Flexible FileLists that act like arrays but know about manipulating file names and paths.
      * Supports parallel execution of tasks.
  DESCRIPTION
  s.homepage = "https://github.com/ruby/rake".freeze
  s.licenses = ["MIT"].map(&:freeze)

  s.files = %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.files.reject! { |f| %w[.rubocop.yml .travis.yml appveyor.yml].include?(f) }

  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.require_paths = ["lib"].map(&:freeze)

  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "2.6.1".freeze
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.2".freeze)
  s.rdoc_options = ["--main", "README.rdoc"].map(&:freeze)

  s.add_development_dependency("bundler".freeze)
  s.add_development_dependency("coveralls".freeze)
  s.add_development_dependency("minitest".freeze)
  s.add_development_dependency("rdoc".freeze)
  s.add_development_dependency("rubocop".freeze)
end
