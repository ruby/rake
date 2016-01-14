#
# Copyright (c) 2008 James M. Lawrence
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

require 'rbconfig'

##
# Alternate implementations of system() and backticks `` on Windows
# for ruby-1.8 and earlier.
#--
# TODO: Remove in Rake 11

module Rake::AltSystem # :nodoc: all
  WINDOWS = RbConfig::CONFIG["host_os"] =~
    %r!(msdos|mswin|djgpp|mingw|[Ww]indows)!

  class << self
    def define_module_function(name, &block)
      define_method(name, &block)
      module_function(name)
    end
  end

  # Non-Windows or ruby-1.9+: same as Kernel versions
  define_module_function :system, &Kernel.method(:system)
  define_module_function :backticks, &Kernel.method(:'`')
  define_module_function :'`', &Kernel.method(:'`')
end
