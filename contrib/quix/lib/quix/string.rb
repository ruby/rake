
class String
  {
    :gsub => :gsubx,
    :gsub! => :gsubx!,
    :sub => :subx,
    :sub! => :subx!,
  }.each_pair { |source, dest|
    # use eval for < 1.8.7 compatibility
    eval %Q{
      def #{dest}(*args)
        if block_given?
          #{source}(*args) {
            yield Regexp.last_match
          }
        else
          #{source}(*args)
        end
      end
    }
  }
end

