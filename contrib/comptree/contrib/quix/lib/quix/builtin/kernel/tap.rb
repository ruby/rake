
unless respond_to? :tap
  module Kernel
    def tap
      yield self
      self
    end
  end
end
