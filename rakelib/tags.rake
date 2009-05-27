#!/usr/bin/env ruby

module Tags
  PROG = ENV['TAGS'] || 'ctags'
  RUBY_FILES = FileList['**/*.rb'].exclude('sys.rb')
  RUBY_FILES.include('**/*.rake')
end

namespace "tags" do
  desc "Generate an Emacs TAGS file"
  task :emacs => Tags::RUBY_FILES do
    puts "Making Emacs TAGS file"
    sh "#{Tags::PROG} -e #{Tags::RUBY_FILES}", :verbose => false
  end
end

desc "Generate the TAGS file"
task :tags => ["tags:emacs"]
