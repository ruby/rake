module Rake

  class ThreadHistoryDisplay
    def initialize(stats)
      @stats   = stats
      @items   = { :_seq_ =>  1  }
      @threads = { :_seq_ => "A" }
    end

    def show
      puts "Job History:"
      stats.each do |stat|
        stat[:data] ||= []
        rename(stat, :thread, threads)
        rename(stat[:data], :item_id, items)
        rename(stat[:data], :new_thread, threads)
        rename(stat[:data], :deleted_thread, threads)
        printf("%8d %2s %-10s %s\n",
          (stat[:time] * 100000).to_i,
          stat[:thread],
          stat[:event],
          stat[:data].map { |k,v| "#{k}:#{v}" }.join(" "))
      end
    end

    private

    def rename(hash, key, renames)
      if hash && hash[key]
        original = hash[key]
        value = renames[original]
        unless value
          value = renames[:_seq_]
          renames[:_seq_] = renames[:_seq_].succ
          renames[original] = value
        end
        hash[key] = value
      end
    end

    attr_reader :stats, :items, :threads
  end

end
