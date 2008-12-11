
class Dir
  class << self
    def empty?(dir)
      entries(dir).join == "..."
    end
  end
end
