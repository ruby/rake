#!/usr/bin/env ruby

# = Extension to Dir
#
# This file contains an extension to the Dir class.  Later versions of
# Ruby support this functionality in the chdir command itself, but we
# provide it here for compatibility with older versions.

unless Dir.methods.include?("indir")

  # Extensions for standard class Dir.
  class Dir

    # Temporarily make +dir+ the current directory for the duration of
    # the block.  When +indir+ returns, the original current directory
    # will be restored.  The name of the new directory is passed to
    # the block.
    #
    # <b>Note:</b> <em>This function is not thread-safe.</em>
    def Dir.indir(dir)
      olddir = Dir.pwd
      Dir.chdir(dir)
      yield(dir)
    ensure
      Dir.chdir(olddir)
    end
  end

end
