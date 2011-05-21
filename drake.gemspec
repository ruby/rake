--- !ruby/object:Gem::Specification 
name: drake
version: !ruby/object:Gem::Version 
  prerelease: 
  version: 0.9.0.0.3.0
platform: ruby
authors: 
- James M. Lawrence
autorequire: 
bindir: bin
cert_chain: []

date: 2011-05-21 00:00:00 Z
dependencies: 
- !ruby/object:Gem::Dependency 
  name: comp_tree
  prerelease: false
  requirement: &id001 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ">="
      - !ruby/object:Gem::Version 
        version: 1.1.3
  type: :runtime
  version_requirements: *id001
- !ruby/object:Gem::Dependency 
  name: session
  prerelease: false
  requirement: &id002 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: "2.4"
  type: :development
  version_requirements: *id002
- !ruby/object:Gem::Dependency 
  name: flexmock
  prerelease: false
  requirement: &id003 !ruby/object:Gem::Requirement 
    none: false
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: 0.8.11
  type: :development
  version_requirements: *id003
description: "      Rake is a Make-like program implemented in Ruby. Tasks\n      and dependencies are specified in standard Ruby syntax.\n"
email: quixoticsycophant@gmail.com
executables: 
- drake
extensions: []

extra_rdoc_files: 
- README.rdoc
- MIT-LICENSE
- TODO
- CHANGES
- CHANGES-drake
- doc/command_line_usage.rdoc
- doc/glossary.rdoc
- doc/parallel.rdoc
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
- doc/release_notes/rake-0.8.5.rdoc
- doc/release_notes/rake-0.8.6.rdoc
- doc/release_notes/rake-0.8.7.rdoc
- doc/release_notes/rake-0.9.0.rdoc
files: 
- .gemtest
- install.rb
- CHANGES
- CHANGES-drake
- MIT-LICENSE
- README.rdoc
- Rakefile
- Rakefile-drake
- TODO
- bin/drake
- lib/rake/alt_system.rb
- lib/rake/application.rb
- lib/rake/classic_namespace.rb
- lib/rake/clean.rb
- lib/rake/cloneable.rb
- lib/rake/contrib/compositepublisher.rb
- lib/rake/contrib/ftptools.rb
- lib/rake/contrib/publisher.rb
- lib/rake/contrib/rubyforgepublisher.rb
- lib/rake/contrib/sshpublisher.rb
- lib/rake/contrib/sys.rb
- lib/rake/default_loader.rb
- lib/rake/dsl.rb
- lib/rake/dsl_definition.rb
- lib/rake/early_time.rb
- lib/rake/ext/core.rb
- lib/rake/ext/module.rb
- lib/rake/ext/string.rb
- lib/rake/ext/time.rb
- lib/rake/file_creation_task.rb
- lib/rake/file_list.rb
- lib/rake/file_task.rb
- lib/rake/file_utils.rb
- lib/rake/file_utils_ext.rb
- lib/rake/gempackagetask.rb
- lib/rake/invocation_chain.rb
- lib/rake/invocation_exception_mixin.rb
- lib/rake/loaders/makefile.rb
- lib/rake/multi_task.rb
- lib/rake/name_space.rb
- lib/rake/packagetask.rb
- lib/rake/parallel.rb
- lib/rake/pathmap.rb
- lib/rake/pseudo_status.rb
- lib/rake/rake_module.rb
- lib/rake/rake_test_loader.rb
- lib/rake/rdoctask.rb
- lib/rake/ruby182_test_unit_fix.rb
- lib/rake/rule_recursion_overflow_error.rb
- lib/rake/runtest.rb
- lib/rake/task.rb
- lib/rake/task_argument_error.rb
- lib/rake/task_arguments.rb
- lib/rake/task_manager.rb
- lib/rake/tasklib.rb
- lib/rake/testtask.rb
- lib/rake/version.rb
- lib/rake/win32.rb
- lib/rake.rb
- test/capture_stdout.rb
- test/check_expansion.rb
- test/check_no_expansion.rb
- test/contrib/test_sys.rb
- test/data/rakelib/test1.rb
- test/data/rbext/rakefile.rb
- test/file_creation.rb
- test/functional/functional_test.rb
- test/functional/session_based_tests.rb
- test/in_environment.rb
- test/lib/application_test.rb
- test/lib/clean_test.rb
- test/lib/definitions_test.rb
- test/lib/dsl_test.rb
- test/lib/earlytime_test.rb
- test/lib/extension_test.rb
- test/lib/file_creation_task_test.rb
- test/lib/file_task_test.rb
- test/lib/filelist_test.rb
- test/lib/fileutils_test.rb
- test/lib/ftp_test.rb
- test/lib/invocation_chain_test.rb
- test/lib/makefile_loader_test.rb
- test/lib/multitask_test.rb
- test/lib/namespace_test.rb
- test/lib/package_task_test.rb
- test/lib/parallel_test.rb
- test/lib/pathmap_test.rb
- test/lib/pseudo_status_test.rb
- test/lib/rake_test.rb
- test/lib/rdoc_task_test.rb
- test/lib/require_test.rb
- test/lib/rules_test.rb
- test/lib/task_arguments_test.rb
- test/lib/task_manager_test.rb
- test/lib/task_test.rb
- test/lib/tasklib_test.rb
- test/lib/test_task_test.rb
- test/lib/testtask_test.rb
- test/lib/top_level_functions_test.rb
- test/lib/win32_test.rb
- test/parallel_setup.rb
- test/rake_test_setup.rb
- test/reqfile.rb
- test/reqfile2.rb
- test/ruby_version_test.rb
- test/serial_setup.rb
- test/shellcommand.rb
- test/test_helper.rb
- test/data/imports/deps.mf
- test/data/sample.mf
- test/data/access/Rakefile
- test/data/chains/Rakefile
- test/data/comments/Rakefile
- test/data/default/Rakefile
- test/data/deprecated_import/Rakefile
- test/data/dryrun/Rakefile
- test/data/file_creation_task/Rakefile
- test/data/imports/Rakefile
- test/data/multidesc/Rakefile
- test/data/namespace/Rakefile
- test/data/statusreturn/Rakefile
- test/data/unittest/Rakefile
- test/data/verbose/Rakefile
- test/data/unittest/subdir
- doc/command_line_usage.rdoc
- doc/example
- doc/example/Rakefile1
- doc/example/Rakefile2
- doc/example/a.c
- doc/example/b.c
- doc/example/main.c
- doc/glossary.rdoc
- doc/jamis.rb
- doc/parallel.rdoc
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
- doc/release_notes/rake-0.8.5.rdoc
- doc/release_notes/rake-0.8.6.rdoc
- doc/release_notes/rake-0.8.7.rdoc
- doc/release_notes/rake-0.9.0.rdoc
homepage: http://drake.rubyforge.org
licenses: []

post_install_message: 
rdoc_options: 
- --line-numbers
- --show-hash
- --main
- README.rdoc
- --title
- "Drake: Distributed Rake"
require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
required_rubygems_version: !ruby/object:Gem::Requirement 
  none: false
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: 1.3.2
requirements: []

rubyforge_project: drake
rubygems_version: 1.8.2
signing_key: 
specification_version: 3
summary: A branch of Rake supporting automatic parallelizing of tasks.
test_files: []

