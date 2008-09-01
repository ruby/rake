
root = File.dirname(__FILE__)
pkgname = File.basename(__FILE__).sub(%r!\.rb\Z!, "")
 
Dir["#{root}/#{pkgname}/**/*.rb"].map { |file|
  # change to relative paths
  file.
  sub(%r!\A#{root}/!, "").
  sub(%r!\.rb\Z!, "")
}.reject { |file|
  file =~ %r!builtin! or
  (file =~ %r!cygwin! and RUBY_PLATFORM !~ %r!cygwin!)
}.each { |file|
  require file
}
