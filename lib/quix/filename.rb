
require 'quix/fileutils'

module Quix
  class Filename < String
    ##########################################
    # new methods

    # extname without the '.'
    def ext
      File.extname(self).sub(%r!\A\.!, "")
    end

    # Name without the .ext
    def stem
      sub(%r!#{File.extname(self)}\Z!, "")
    end

    # File.size(self)
    def read_size
      File.size(self)
    end

    # File.size?(self)
    def read_size?
      File.size?(self)
    end

    # See Quix::FileUtils#rename_file
    def rename(new_name)
      Quix::FileUtils.rename_file(self, new_name)
    end

    # See Quix::FileUtils#replace_file
    def replace(&block)
      Quix::FileUtils.replace_file(self, &block)
    end

    ##########################################
    # methods with arguments

    def join(filename)
      File.join(self, filename)
    end

    def chmod(mode)
      File.chmod(mode, self)
    end

    def chown(owner, group)
      File.chown(owner, group, self)
    end
    
    def lchmod(mode)
      File.lchmod(mode, self)
    end

    def lchown(owner, group)
      File.lchown(owner, group, self)
    end
    
    def compare(other)
      File.compare(self, other)
    end

    ##########################################
    # no-argument methods

    %w[
       # from class IO
       read
       readlines
       foreach

       # from class File
       atime
       basename
       blockdev?
       chardev?
       ctime
       delete
       unlink
       directory?
       dirname
       executable?
       executable_real?
       exist?
       expand_path
       extname
       file?
       ftype
       grpowned?
       identical?
       lstat
       mtime
       owned?
       pipe?
       readable?
       readable_real?
       readlink
       safe_unlink
       setgid?
       setuid?
       socket?
       split
       stat
       sticky?
       symlink?
       writeable?
       writeable_real?
       zero?
    ].each { |name|
      sym = name.to_sym
      define_method(sym) {
        File.send(sym, self)
      }
    }

    ##########################################
    # aliases

    alias_method :contents, :read
    alias_method :contents_size, :read_size
    alias_method :contents_size?, :read_size?
    alias_method :expand, :expand_path
  end
end
