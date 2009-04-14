--- !ruby/object:Gem::Specification 
name: rake
version: !ruby/object:Gem::Version 
  version: 0.8.4.99
platform: ruby
authors: 
- Jim Weirich
autorequire: 
bindir: bin
cert_chain: []

date: 2009-04-14 00:00:00 -04:00
default_executable: rake
dependencies: []

description: Rake is a Make-like program implemented in Ruby. Tasks and dependencies are specified in standard Ruby syntax.
email: jim@weirichhouse.org
executables: 
- rake
extensions: []

extra_rdoc_files: 
- README
- MIT-LICENSE
- TODO
- CHANGES
- doc/command_line_usage.rdoc
- doc/glossary.rdoc
- doc/proto_rake.rdoc
- doc/rakefile.rdoc
- doc/rational.rdoc
- doc/release_notes/rake-0.4.14.rdoc
- doc/release_notes/rake-0.4.15.rdoc
- doc/release_notes/rake-0.5.0.rdoc
- doc/release_notes/rake-0.5.3.rdoc
- doc/release_notes/rake-0.5.4.rdoc
- doc/release_notes/rake-0.6.0.rdoc
- doc/release_notes/rake-0.7.0.rdoc
- doc/release_notes/rake-0.7.1.rdoc
- doc/release_notes/rake-0.7.2.rdoc
- doc/release_notes/rake-0.7.3.rdoc
- doc/release_notes/rake-0.8.0.rdoc
- doc/release_notes/rake-0.8.2.rdoc
- doc/release_notes/rake-0.8.3.rdoc
- doc/release_notes/rake-0.8.4.rdoc
files: 
- install.rb
- CHANGES
- MIT-LICENSE
- Rakefile
- README
- TODO
- bin/rake
- lib/rake/alt_system.rb
- lib/rake/classic_namespace.rb
- lib/rake/clean.rb
- lib/rake/contrib/compositepublisher.rb
- lib/rake/contrib/ftptools.rb
- lib/rake/contrib/publisher.rb
- lib/rake/contrib/rubyforgepublisher.rb
- lib/rake/contrib/sshpublisher.rb
- lib/rake/contrib/sys.rb
- lib/rake/gempackagetask.rb
- lib/rake/loaders/makefile.rb
- lib/rake/packagetask.rb
- lib/rake/rake_test_loader.rb
- lib/rake/rdoctask.rb
- lib/rake/ruby182_test_unit_fix.rb
- lib/rake/runtest.rb
- lib/rake/tasklib.rb
- lib/rake/testtask.rb
- lib/rake/win32.rb
- lib/rake.rb
- test/capture_stdout.rb
- test/check_expansion.rb
- test/check_no_expansion.rb
- test/contrib/test_sys.rb
- test/data/rakelib/test1.rb
- test/data/rbext/rakefile.rb
- test/filecreation.rb
- test/functional.rb
- test/in_environment.rb
- test/rake_test_setup.rb
- test/reqfile.rb
- test/reqfile2.rb
- test/session_functional.rb
- test/shellcommand.rb
- test/test_application.rb
- test/test_clean.rb
- test/test_definitions.rb
- test/test_earlytime.rb
- test/test_extension.rb
- test/test_file_creation_task.rb
- test/test_file_task.rb
- test/test_filelist.rb
- test/test_fileutils.rb
- test/test_ftp.rb
- test/test_invocation_chain.rb
- test/test_makefile_loader.rb
- test/test_multitask.rb
- test/test_namespace.rb
- test/test_package_task.rb
- test/test_pathmap.rb
- test/test_pseudo_status.rb
- test/test_rake.rb
- test/test_rdoc_task.rb
- test/test_require.rb
- test/test_rules.rb
- test/test_task_arguments.rb
- test/test_task_manager.rb
- test/test_tasklib.rb
- test/test_tasks.rb
- test/test_test_task.rb
- test/test_top_level_functions.rb
- test/test_win32.rb
- test/data/imports/deps.mf
- test/data/sample.mf
- test/data/chains/Rakefile
- test/data/default/Rakefile
- test/data/dryrun/Rakefile
- test/data/file_creation_task/Rakefile
- test/data/imports/Rakefile
- test/data/multidesc/Rakefile
- test/data/namespace/Rakefile
- test/data/statusreturn/Rakefile
- test/data/unittest/Rakefile
- test/data/unittest/subdir
- doc/command_line_usage.rdoc
- doc/example
- doc/example/a.c
- doc/example/b.c
- doc/example/main.c
- doc/example/Rakefile1
- doc/example/Rakefile2
- doc/glossary.rdoc
- doc/jamis.rb
- doc/proto_rake.rdoc
- doc/rake.1.gz
- doc/rakefile.rdoc
- doc/rational.rdoc
- doc/release_notes
- doc/release_notes/rake-0.4.14.rdoc
- doc/release_notes/rake-0.4.15.rdoc
- doc/release_notes/rake-0.5.0.rdoc
- doc/release_notes/rake-0.5.3.rdoc
- doc/release_notes/rake-0.5.4.rdoc
- doc/release_notes/rake-0.6.0.rdoc
- doc/release_notes/rake-0.7.0.rdoc
- doc/release_notes/rake-0.7.1.rdoc
- doc/release_notes/rake-0.7.2.rdoc
- doc/release_notes/rake-0.7.3.rdoc
- doc/release_notes/rake-0.8.0.rdoc
- doc/release_notes/rake-0.8.2.rdoc
- doc/release_notes/rake-0.8.3.rdoc
- doc/release_notes/rake-0.8.4.rdoc
has_rdoc: true
homepage: http://rake.rubyforge.org
post_install_message: 
rdoc_options: 
- --line-numbers
- --inline-source
- --main
- README
- --title
- Rake -- Ruby Make
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: rake
rubygems_version: 1.3.1
signing_key: 
specification_version: 2
summary: Ruby based make-like utility.
test_files: []

