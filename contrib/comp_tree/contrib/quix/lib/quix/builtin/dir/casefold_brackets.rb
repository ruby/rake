
class << Dir
   remove_method :[]
   def [](pattern)
      Dir.glob(pattern, File::FNM_CASEFOLD)
   end
end
