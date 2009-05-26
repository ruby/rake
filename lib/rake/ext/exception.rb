require 'rake/invocation_exception_mixin'

class Exception
  include Rake::InvocationExceptionMixin
end
