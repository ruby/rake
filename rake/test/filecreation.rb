#!/usr/bin/env ruby

require 'ftools'

module FileCreation
  def create_timed_files(oldfile, newfile)
    return if File.exist?(oldfile) && File.exist?(newfile)
    old_time = create_file(oldfile)
    while create_file(newfile) <= old_time
      sleep(0.1)
      File.delete(newfile) rescue nil
    end
  end

  def create_file(name)
    open(name, "w") {|f| f.puts "HI" } if ! File.exist?(name)
    File.new(name).mtime
  end

  def delete_file(name)
    File.delete(name) rescue nil
  end
end

