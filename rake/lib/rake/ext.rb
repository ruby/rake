#!/usr/bin/env ruby

class String
  unless instance_methods.include? "ext"
    # Replace the file extension with +newext+.  If there is no
    # extenson on the string, append the new extension to the end.  If
    # the new extension is not given, or is the empty string, remove
    # any existing extension.
    #
    # +ext+ is a user added method for the String class.
    def ext(newext='')
      return self.dup if ['.', '..'].include? self
      if newext != ''
 	newext = (newext =~ /^\./) ? newext : ("." + newext)
      end
      dup.sub!(%r(([^/\\])\.[^./\\]*$)) { $1 + newext } || self + newext
    end
  end
end

class Array
  unless instance_methods.include? "ext"
    # Return a new array with <tt>String#ext</tt> method applied to
    # each member of the array.
    #
    # This method is a shortcut for:
    #
    #    array.collect { |item| item.ext(newext) }
    #
    # +ext+ is a user added method for the Array class.
    def ext(newext='')
      collect { |fn| fn.ext(newext) }
    end
  end
end
