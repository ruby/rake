module Rake

  # Same as a regular task, but the immediate prerequisites are done in
  # parallel using Ruby threads.
  #
  class MultiTask < Task
    private
    def invoke_prerequisites(args, invocation_chain)
      futures = @prerequisites.collect do |p|
        application.thread_pool.future(p) do |r|
          application[r, @scope].invoke_with_call_chain(args, invocation_chain)
        end
      end
      futures.each { |f| f.call }
    end
  end

end
