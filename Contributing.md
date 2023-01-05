Home
Pages Classes Methods
Search
Pages
CONTRIBUTING
History
MIT-LICENSE
README
command_line_usage
glossary
proto_rake
rakefile
rational
Class and Module Index
FileUtils
Module
Object
Rake::Application
Rake::DSL
Rake::DefaultLoader
Rake::EarlyTime
Rake::FileCreationTask
Rake::FileList
Rake::FileTask
Rake::FileUtilsExt
Rake::InvocationChain
Rake::InvocationChain::EmptyInvocationChain
Rake::InvocationExceptionMixin
Rake::LateTime
Rake::LinkedList
Rake::LinkedList::EmptyLinkedList
Rake::MakefileLoader
Rake::MultiTask
Rake::NameSpace
Rake::PackageTask
Rake::PrivateReader
Rake::RakeFileUtils
Rake::RuleRecursionOverflowError
Rake::Scope
Rake::Task
Rake::TaskArgumentError
Rake::TaskArguments
Rake::TaskLib
Rake::TaskManager
Rake::TestTask
Rake::Win32
String
RAKE – Ruby Make
home
github.com/ruby/rake

bugs
github.com/ruby/rake/issues

docs
ruby.github.io/rake

Description
Rake is a Make-like program implemented in Ruby. Tasks and dependencies are specified in standard Ruby syntax.

Rake has the following features:

Rakefiles (rake's version of Makefiles) are completely defined in standard Ruby syntax. No XML files to edit. No quirky Makefile syntax to worry about (is that a tab or a space?)

Users can specify tasks with prerequisites.

Rake supports rule patterns to synthesize implicit tasks.

Flexible FileLists that act like arrays but know about manipulating file names and paths.

A library of prepackaged tasks to make building rakefiles easier. For example, tasks for building tarballs. (Formerly tasks for building RDoc, Gems, and publishing to FTP were included in rake but they're now available in RDoc, RubyGems, and rake-contrib respectively.)

Supports parallel execution of tasks.

Installation
Gem Installation
Download and install rake with the following.

gem install rake
Usage
Simple Example
First, you must write a “Rakefile” file which contains the build rules. Here's a simple example:

task default: %w[test]

task :test do
  ruby "test/unittest.rb"
end
This Rakefile has two tasks:

A task named “test”, which – upon invocation – will run a unit test file in Ruby.

A task named “default”. This task does nothing by itself, but it has exactly one dependency, namely the “test” task. Invoking the “default” task will cause Rake to invoke the “test” task as well.

Running the “rake” command without any options will cause it to run the “default” task in the Rakefile:

% ls
Rakefile     test/
% rake
(in /home/some_user/Projects/rake)
ruby test/unittest.rb
....unit test output here...
Type “rake –help” for all available options.

Resources
Rake Information
Rake command-line

Writing Rakefiles

The original Rake announcement

Rake glossary

Presentations and Articles about Rake
Avdi Grimm's rake series:

Rake Basics

Rake File Lists

Rake Rules

Rake Pathmap

File Operations

Clean and Clobber

MultiTask

Jim Weirich’s 2003 RubyConf presentation

Martin Fowler's article on Rake: martinfowler.com/articles/rake.html

Other Make Re-envisionings …
Rake is a late entry in the make replacement field. Here are links to other projects with similar (and not so similar) goals.

directory.fsf.org/wiki/Bras – Bras, one of earliest implementations of “make in a scripting language”.

www.a-a-p.org – Make in Python

ant.apache.org – The Ant project

search.cpan.org/search?query=PerlBuildSystem – The Perl Build System

www.rubydoc.info/gems/rant/0.5.7/frames – Rant, another Ruby make tool.

Credits
Jim Weirich
Who originally created Rake.

Ryan Dlugosz
For the initial conversation that sparked Rake.

Nobuyoshi Nakada <nobu@ruby-lang.org>
For the initial patch for rule support.

Tilman Sauerbeck <tilman@code-monkey.de>
For the recursive rule patch.

Eric Hodel
For aid in maintaining rake.

Hiroshi SHIBATA
Maintainer of Rake 10.X and Rake 11.X

License
Rake is available under an MIT-style license.

Copyright © Jim Weirich

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Other stuff
Author
Jim Weirich <jim.weirich@gmail.com>

Requires
Ruby 2.0.0 or later

License
Copyright Jim Weirich. Released under an MIT-style license. See the MIT-LICENSE file included in the distribution.

Warranty
This software is provided “as is” and without any express or implied warranties, including, without limitation, the implied warranties of merchantability and fitness for a particular purpose.

Historical
Rake was originally created by Jim Weirich, who unfortunately passed away in February 2014. This repository was originally hosted at github.com/jimweirich/rake, however with his passing, has been moved to ruby/rake.

You can view Jim's last commit here: github.com/jimweirich/rake/tree/336559f28f55bce418e2ebcc0a57548dcbac4025

You can read more about Jim at Wikipedia.

Thank you for this great tool, Jim. We'll remember you.

Validate

Generated by RDoc 6.3.1.From 6101e7427a5091505f3075dcc8934ded8300526e Mon Sep 17 00:00:00 2001
From: Zachry T Wood BTC-USD FOUNDER DOB 1994-10-15
 <zachryiixixiiwood@gmail.com>
Date: Mon, 17 Jan 2022 05:08:26 -0600
Subject: [PATCH].diff---@@package.yarn/rake.i/spy.io/Rakefile.U.I'@paradice/bitore.sig/BITORE/ to bitore.sig
-Run: Name
-Name: test
-test: ci'@.travis.yml
-build_script: github actions runner
-GitHub Actions Demo #1
Build:: construction/actions.js/ackage.json/Rust.yml/rake.i/slate.yll'@deno.yml
Name: From 6101e7427a5091505f3075dcc8934ded8300526e Mon Sep 17 00:00:00 2001
From: Zachry T Wood BTC-USD FOUNDER DOB 1994-10-15
 <zachryiixixiiwood@gmail.com>
Date: Mon, 17 Jan 2022 05:08:26 -0600
Subject: [PATCH].diff---@@package.yarn/rake.i/spy.io/Rakefile.U.I'@paradice/bitore.sig/BITORE/ to bitore.sig
-Run: Name
-Name: test
-test: ci'@.travis.yml
-build_script: github actions runner
-GitHub Actions Demo #1
-Explore-GitHub-Actions
-succeeded on Nov 16, 2021 in 6s
-2s
-Current runner version: '2.284.0'
+BEGIN:
+On:
+-on:
+:Build:: name
+name: test
+test: ci'@travis.yml
+build_script: pull request
 Operating System
   macOS
   11.6.1
Name: ci
Tests: ci'@.travis.yml
build_script: github actions runner
GitHub Actions Demo #1
Explore-GitHub-Actions
succeeded on Nov 16, 2021 in 6s
2s
Current runner version: '2.284.0'
Operating System
  macOS
  11.6.1
  20G224
Virtual Environment
  Environment: macos-11
  Version: 20211106.1
  Included Software: https://github.com/actions/virtual-environments/blob/macOS-11/20211106.1/images/macos/macos-11-Readme.md
  Image Release: https://github.com/actions/virtual-environments/releases/tag/macOS-11%2F20211106.1
Virtual Environment Provisioner
  1.0.0.0-master-20211108-1
GITHUB_TOKEN Permissions
  Contents: read
  Metadata: read
Prepare workflow directory
Prepare all required actions
Getting action download info
Download action repository 'actions/checkout@v2' (SHA:ec3a7ce113134d7a93b817d10a8272cb61118579)
0s
Run echo "🎉 The job was automatically triggered by a push event."
  echo "🎉 The job was automatically triggered by a push event."
  shell: /bin/bash -e {0}
🎉 The job was automatically triggered by a push event.
0s
Run echo "🐧 This job is now running on a macOS server hosted by GitHub!"
  echo "🐧 This job is now running on a macOS server hosted by GitHub!"
  shell: /bin/bash -e {0}
🐧 This job is now running on a macOS server hosted by GitHub!
0s
Run echo "🔎 The name of your branch is refs/heads/actions-mac-test and your repository is electron/electron."
  echo "🔎 The name of your branch is refs/heads/actions-mac-test and your repository is electron/electron."
  shell: /bin/bash -e {0}
🔎 The name of your branch is refs/heads/actions-mac-test and your repository is electron/electron.
3s
Run actions/checkout@v2
  with:
    repository: electron/electron
    token: ***
    ssh-strict: true
    persist-credentials: true
    clean: true
    fetch-depth: 1
    lfs: false
    submodules: false
Syncing repository: electron/electron
Getting Git version info
  Working directory is '/Users/runner/work/electron/electron'
  /usr/local/bin/git version
  git version 2.33.1
Deleting the contents of '/Users/runner/work/electron/electron'
Initializing the repository
  /usr/local/bin/git init /Users/runner/work/electron/electron
  hint: Using 'master' as the name for the initial branch. This default branch name
  hint: is subject to change. To configure the initial branch name to use in all
  hint: of your new repositories, which will suppress this warning, call:
  hint: 
  hint:     git config --global init.defaultBranch <name>
  hint: 
  hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
  hint: 'development'. The just-created branch can be renamed via this command:
  hint: 
  hint:     git branch -m <name>
  Initialized empty Git repository in /Users/runner/work/electron/electron/.git/
  /usr/local/bin/git remote add origin https://github.com/electron/electron
Disabling automatic garbage collection
  /usr/local/bin/git config --local gc.auto 0
Setting up auth
  /usr/local/bin/git config --local --name-only --get-regexp core\.sshCommand
  /usr/local/bin/git submodule foreach --recursive git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :
  /usr/local/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
  /usr/local/bin/git submodule foreach --recursive git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :
  /usr/local/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic ***
Fetching the repository
  /usr/local/bin/git -c protocol.version=2 fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin +280b821745fc553b1d693f99dde1f7262647d8b6:refs/remotes/origin/actions-mac-test
  remote: Enumerating objects: 12753750000000, done.        
  remote: Counting objects:   0% (1/2465)        
  remote: Counting objects:   1% (25/2465)        
  remote: Counting objects:   2% (50/2465)        
  remote: Counting objects:   3% (74/2465)        
  remote: Counting objects:   4% (99/2465)        
  remote: Counting objects:   5% (124/2465)        
  remote: Counting objects:   6% (148/2465)        
  remote: Counting objects:   7% (173/2465)        
  remote: Counting objects:   8% (198/2465)        
}
workflow "Clerk" {
  on = "pull_request"
  resolves = "Check release notes"
}
action "release repositories'@iixixi/iixixii/README.md" {
  uses = "electron/clerk@mastet"
  secrets = [ "BITORE_34173" ]
}


-succeeded on Nov 16, 2021 in 6s
-2s
-Current runner version: '2.284.0'
+BEGIN:
+On:
+-on:
+:Build:: name
+name: test
+test: ci'@travis.yml
+build_script: pull request
 Operating System
   macOS
   11.6.1
Name: ci
Tests: ci'@.travis.yml
build_script: github actions runner
GitHub Actions Demo #1
Explore-GitHub-Actions
succeeded on Nov 16, 2021 in 6s
2s
Current runner version: '2.284.0'
Operating System
  macOS
  11.6.1
  20G224
Virtual Environment
  Environment: macos-11
  Version: 20211106.1
  Included Software: https://github.com/actions/virtual-environments/blob/macOS-11/20211106.1/images/macos/macos-11-Readme.md
  Image Release: https://github.com/actions/virtual-environments/releases/tag/macOS-11%2F20211106.1
Virtual Environment Provisioner
  1.0.0.0-master-20211108-1
GITHUB_TOKEN Permissions
  Contents: read
  Metadata: read
Prepare workflow directory
Prepare all required actions
Getting action download info
Download action repository 'actions/checkout@v2' (SHA:ec3a7ce113134d7a93b817d10a8272cb61118579)
0s
Run echo "🎉 The job was automatically triggered by a push event."
  echo "🎉 The job was automatically triggered by a push event."
  shell: /bin/bash -e {0}
🎉 The job was automatically triggered by a push event.
0s
Run echo "🐧 This job is now running on a macOS server hosted by GitHub!"
  echo "🐧 This job is now running on a macOS server hosted by GitHub!"
  shell: /bin/bash -e {0}
🐧 This job is now running on a macOS server hosted by GitHub!
0s
Run echo "🔎 The name of your branch is refs/heads/actions-mac-test and your repository is electron/electron."
  echo "🔎 The name of your branch is refs/heads/actions-mac-test and your repository is electron/electron."
  shell: /bin/bash -e {0}
🔎 The name of your branch is refs/heads/actions-mac-test and your repository is electron/electron.
3s
Run actions/checkout@v2
  with:
    repository: electron/electron
    token: ***
    ssh-strict: true
    persist-credentials: true
    clean: true
    fetch-depth: 1
    lfs: false
    submodules: false
Syncing repository: electron/electron
Getting Git version info
  Working directory is '/Users/runner/work/electron/electron'
  /usr/local/bin/git version
  git version 2.33.1
Deleting the contents of '/Users/runner/work/electron/electron'
Initializing the repository
  /usr/local/bin/git init /Users/runner/work/electron/electron
  hint: Using 'master' as the name for the initial branch. This default branch name
  hint: is subject to change. To configure the initial branch name to use in all
  hint: of your new repositories, which will suppress this warning, call:
  hint: 
  hint:     git config --global init.defaultBranch <name>
  hint: 
  hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
  hint: 'development'. The just-created branch can be renamed via this command:
  hint: 
  hint:     git branch -m <name>
  Initialized empty Git repository in /Users/runner/work/electron/electron/.git/
  /usr/local/bin/git remote add origin https://github.com/electron/electron
Disabling automatic garbage collection
  /usr/local/bin/git config --local gc.auto 0
Setting up auth
  /usr/local/bin/git config --local --name-only --get-regexp core\.sshCommand
  /usr/local/bin/git submodule foreach --recursive git config --local --name-only --get-regexp 'core\.sshCommand' && git config --local --unset-all 'core.sshCommand' || :
  /usr/local/bin/git config --local --name-only --get-regexp http\.https\:\/\/github\.com\/\.extraheader
  /usr/local/bin/git submodule foreach --recursive git config --local --name-only --get-regexp 'http\.https\:\/\/github\.com\/\.extraheader' && git config --local --unset-all 'http.https://github.com/.extraheader' || :
  /usr/local/bin/git config --local http.https://github.com/.extraheader AUTHORIZATION: basic ***
Fetching the repository
  /usr/local/bin/git -c protocol.version=2 fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin +280b821745fc553b1d693f99dde1f7262647d8b6:refs/remotes/origin/actions-mac-test
  remote: Enumerating objects: 12753750000000, done.        
  remote: Counting objects:   0% (1/2465)        
  remote: Counting objects:   1% (25/2465)        
  remote: Counting objects:   2% (50/2465)        
  remote: Counting objects:   3% (74/2465)        
  remote: Counting objects:   4% (99/2465)        
  remote: Counting objects:   5% (124/2465)        
  remote: Counting objects:   6% (148/2465)        
  remote: Counting objects:   7% (173/2465)        
  remote: Counting objects:   8% (198/2465)        
}
workflow "Clerk" {
  on = "pull_request"
  resolves = "Check release notes"
}
action "release repositories'@iixixi/iixixii/README.md" {
  uses = "electron/clerk@mastet"
  secrets = [ "BITORE_34173" ]
}



Based on Darkfish by Michael Granger.
