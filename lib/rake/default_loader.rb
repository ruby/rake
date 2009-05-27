module Rake
  
  # Default Rakefile loader used by +import+.
  class DefaultLoader
    def load(fn)
      Kernel.load(File.expand_path(fn))
    end
  end

end
