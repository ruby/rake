
module CompTree
  module RetriableFork
    HAVE_FORK = lambda {
      begin
        process_id = fork { }
        Process.wait(process_id)
      rescue NotImplementedError
        return false
      end
      true
    }.call

    def fork(retry_wait = 10, retry_max = 10, &block)
      num_retries = 0
      begin
        Process.fork(&block)
      rescue Errno::EAGAIN
        num_retries += 1
        if num_retries == retry_max
          message = %Q{
            ****************************************************************
            Maximum number of EAGAIN signals reached (#{retry_max})
            ****************************************************************

            Either increase your process limit permission (consult your
            OS manual) or run this script as superuser.
  
            ****************************************************************
          }
          STDERR.puts(message.gsub(%r!^[ \t]+!, ""))
          raise
        end
        STDERR.puts "Caught EGAIN. Retrying in #{retry_wait} seconds."
        sleep(retry_wait)
        retry
      end
    end
    module_function :fork
  end
end

