#!/usr/bin/env ruby

class String
  unless instance_methods.include? "ext"
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
    def ext(newext='')
      collect { |fn| fn.ext(newext) }
    end
  end
end
