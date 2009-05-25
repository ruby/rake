# ###########################################################################
# This a FileUtils extension that defines several additional commands to be
# added to the FileUtils utility functions.
#
module FileUtils
  RUBY = File.join(
    Config::CONFIG['bindir'],
    Config::CONFIG['ruby_install_name'] + Config::CONFIG['EXEEXT']).
    sub(/.*\s.*/m, '"\&"')

  OPT_TABLE['sh']  = %w(noop verbose)
  OPT_TABLE['ruby'] = %w(noop verbose)

  # Run the system command +cmd+. If multiple arguments are given the command
  # is not run with the shell (same semantics as Kernel::exec and
  # Kernel::system).
  #
  # Example:
  #   sh %{ls -ltr}
  #
  #   sh 'ls', 'file with spaces'
  #
  #   # check exit status after command runs
  #   sh %{grep pattern file} do |ok, res|
  #     if ! ok
  #       puts "pattern not found (status = #{res.exitstatus})"
  #     end
  #   end
  #
  def sh(*cmd, &block)
    options = (Hash === cmd.last) ? cmd.pop : {}
    unless block_given?
      show_command = cmd.join(" ")
      show_command = show_command[0,42] + "..." unless $trace
      # TODO code application logic heref show_command.length > 45
      block = lambda { |ok, status|
        ok or fail "Command failed with status (#{status.exitstatus}): [#{show_command}]"
      }
    end
    set_verbose_option(options)
    options[:noop]    ||= RakeFileUtils.nowrite_flag
    rake_check_options options, :noop, :verbose
    rake_output_message cmd.join(" ") if options[:verbose]
    unless options[:noop]
      res = rake_system(*cmd)
      status = $?
      status = PseudoStatus.new(1) if !res && status.nil?
      block.call(res, status)
    end
  end

  def set_verbose_option(options)
    if RakeFileUtils.verbose_flag.nil? && options[:verbose].nil?
      options[:verbose] = true
    elsif options[:verbose].nil?
      options[:verbose] ||= RakeFileUtils.verbose_flag
    end
  end
  private :set_verbose_option

  def rake_system(*cmd)
    Rake::AltSystem.system(*cmd)
  end
  private :rake_system

  # Run a Ruby interpreter with the given arguments.
  #
  # Example:
  #   ruby %{-pe '$_.upcase!' <README}
  #
  def ruby(*args,&block)
    options = (Hash === args.last) ? args.pop : {}
    if args.length > 1 then
      sh(*([RUBY] + args + [options]), &block)
    else
      sh("#{RUBY} #{args.first}", options, &block)
    end
  end

  LN_SUPPORTED = [true]

  #  Attempt to do a normal file link, but fall back to a copy if the link
  #  fails.
  def safe_ln(*args)
    unless LN_SUPPORTED[0]
      cp(*args)
    else
      begin
        ln(*args)
      rescue StandardError, NotImplementedError => ex
        LN_SUPPORTED[0] = false
        cp(*args)
      end
    end
  end

  # Split a file path into individual directory names.
  #
  # Example:
  #   split_all("a/b/c") =>  ['a', 'b', 'c']
  #
  def split_all(path)
    head, tail = File.split(path)
    return [tail] if head == '.' || tail == '/'
    return [head, tail] if head == '/'
    return split_all(head) + [tail]
  end
end
