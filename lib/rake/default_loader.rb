module Rake
  
  # Default Rakefile loader used by +import+.
  class DefaultLoader
    def load(fn)
      Rake::Environment.load_rakefile(File.expand_path(fn))
    end
  end

end
