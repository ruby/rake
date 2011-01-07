#!/usr/bin/env ruby

module Tags
  PROG = ENV['TAGS'] || 'ctags'

  RAKEFILES = FileList['Rakefile', '**/*.rake']

  FILES = FileList['**/*.rb', '**/*.js'] + RAKEFILES
  FILES.exclude('pkg', 'dist')

  RVM_GEMDIR = (File.join(`rvm gemdir`.strip, "gems") rescue nil)
  DIR_LIST = ['.']
  DIR_LIST << RVM_GEMDIR if RVM_GEMDIR && File.exists?(RVM_GEMDIR)
  DIRS = DIR_LIST.join(" ")

  module_function

  # Convert key_word to --key-word.
  def keyword(key)
    k = key.to_s.gsub(/_/, '-')
    (k.length == 1) ? "-#{k}" : "--#{k}"
  end

  # Run ctags command
  def run(*args)
    opts = {
      :e => true,
      :totals => true,
      :recurse => true,
    }
    opts = opts.merge(args.pop) if args.last.is_a?(Hash)
    command_args = opts.map { |k, v|
      (v == true) ? keyword(k) : "#{keyword(k)}=#{v}"
    }.join(" ")
    sh %{#{Tags::PROG} #{command_args} #{args.join(' ')}}
  end
end

namespace "tags" do
  desc "Generate an Emacs TAGS file"
   task :emacs => Tags::FILES do
    puts "Making Emacs TAGS file"
    verbose(true) do
      Tags.run(Tags::DIRS)
      Tags.run(Tags::RAKEFILES,
        :language_force => "ruby",
        :append => true)
    end
  end
end

desc "Generate the TAGS file"
task :tags => ["tags:emacs"]

