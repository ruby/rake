
class << Dir
  remove_method :[]
  def [](pattern)
    Dir.glob(pattern, File::FNM_CASEFOLD)
  end

  alias_method :glob__original, :glob
  def glob(pattern, flags = 0)
    glob__original(pattern, File::FNM_CASEFOLD | flags)
  end
end
