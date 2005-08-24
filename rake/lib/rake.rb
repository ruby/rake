#!/usr/bin/env ruby

#--
# Copyright (c) 2003, 2004 Jim Weirich
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
# = Rake -- Ruby Make
# 
# This is the main file for the Rake application.  Normally it is
# referenced as a library via a require statement, but it can be
# distributed independently as an application.

RAKEVERSION = '0.5.4.6'

require 'rbconfig'
require 'ftools'
require 'getoptlong'
require 'fileutils'
require 'singleton'

$last_comment = nil
$show_tasks = nil
$show_prereqs = nil
$trace = nil
$dryrun = nil
$silent = false

# Some objects are dupable, some are not.  So we define a version of
# dup (called rake_dup) that returns self on the handful of classes
# that are not dupable.

module Kernel
  # Duplicate an object if it can be duplicated.  If it can not be
  # cloned or duplicated, then just return the original object.
  def rake_dup()
    dup
  end
end

[NilClass, FalseClass, TrueClass, Fixnum, Symbol].each do |clazz|
  clazz.class_eval {
    # Duplicate an object if it can be duplicated.  If it can not be
    # cloned or duplicated, then just return the original object.
    def rake_dup() self end
  }
end

######################################################################
# User defined methods to be added to String.
#
class String
  unless instance_methods.include? "ext"
    # Replace the file extension with +newext+.  If there is no
    # extenson on the string, append the new extension to the end.  If
    # the new extension is not given, or is the empty string, remove
    # any existing extension.
    #
    # +ext+ is a user added method for the String class.
    def ext(newext='')
      return self.dup if ['.', '..'].include? self
      if newext != ''
 	newext = (newext =~ /^\./) ? newext : ("." + newext)
      end
      dup.sub!(%r(([^/\\])\.[^./\\]*$)) { $1 + newext } || self + newext
    end
  end
end


######################################################################
module Rake

  class << self
    # Current Rake Application
    def application
      @application ||= RakeApp.new
    end

    def application=(app)
      fail "RakeApp already exists" if defined?(@application)
      @application = app
    end
  end

  module Cloneable
    def clone
      sibling = self.class.new
      instance_variables.each do |ivar|
        value = self.instance_variable_get(ivar)
        sibling.instance_variable_set(ivar, value.rake_dup)
      end
      sibling
    end
    alias dup clone
  end
end

module Rake
  ######################################################################
  # A Task is the basic unit of work in a Rakefile.  Tasks have
  # associated actions (possibly more than one) and a list of
  # prerequisites.  When invoked, a task will first ensure that all of
  # its prerequisites have an opportunity to run and then it will
  # execute its own actions.
  #
  # Tasks are not usually created directly using the new method, but
  # rather use the +file+ and +task+ convenience methods.
  #
  class Task
    TASKS = Hash.new
    RULES = Array.new
    
    # List of prerequisites for a task.
    attr_reader :prerequisites
    
    # Comment for this task.
    attr_accessor :comment
    
    # Source dependency for rule synthesized tasks.  Nil if task was not
    # sythesized from a rule.
    attr_accessor :source
    
    # Create a task named +task_name+ with no actions or prerequisites..
    # use +enhance+ to add actions and prerequisites.
    def initialize(task_name)
      @name = task_name
      @prerequisites = FileList[]
      @actions = []
      @already_invoked = false
      @comment = nil
    end
    
    # Enhance a task with prerequisites or actions.  Returns self.
    def enhance(deps=nil, &block)
      @prerequisites |= deps if deps
      @actions << block if block_given?
      self
    end
    
    # Name of the task.
    def name
      @name.to_s
    end
    
    # Invoke the task if it is needed.  Prerequites are invoked first.
    def invoke
      if $trace
	puts "** Invoke #{name} #{format_trace_flags}"
      end
      return if @already_invoked
      @already_invoked = true
      @prerequisites.each { |n| Rake::Task[n].invoke }
      execute if needed?
    end
    
    # Format the trace flags for display.
    def format_trace_flags
      flags = []
      flags << "first_time" unless @already_invoked
      flags << "not_needed" unless needed?
      flags.empty? ? "" : "(" + flags.join(", ") + ")"
    end
    private :format_trace_flags
    
    # Execute the actions associated with this task.
    def execute
      if $dryrun
	puts "** Execute (dry run) #{name}"
	return
      end
      if $trace
	puts "** Execute #{name}"
      end
      self.class.enhance_with_matching_rule(name) if @actions.empty?
      @actions.each { |act| result = act.call(self) }
    end
    
    # Is this task needed?
    def needed?
      true
    end
    
    # Timestamp for this task.  Basic tasks return the current time for
    # their time stamp.  Other tasks can be more sophisticated.
    def timestamp
      @prerequisites.collect { |p| Rake::Task[p].timestamp }.max || Time.now
    end
    
    # Add a comment to the task.  If a comment alread exists, separate
    # the new comment with " / ".
    def add_comment(comment)
      return if ! $last_comment
      if @comment 
	@comment << " / "
      else
	@comment = ''
      end
      @comment << $last_comment
      $last_comment = nil
    end
    
    # Return a string describing the internal state of a task.  Useful
    # for debugging.
    def investigation
      result = "------------------------------\n"
      result << "Investigating #{name}\n" 
      result << "class: #{self.class}\n"
      result <<  "task needed: #{needed?}\n"
      result <<  "timestamp: #{timestamp}\n"
      result << "pre-requisites: \n"
      prereqs = @prerequisites.collect {|name| Rake::Task[name]}
      prereqs.sort! {|a,b| a.timestamp <=> b.timestamp}
      prereqs.each do |p|
	result << "--#{p.name} (#{p.timestamp})\n"
      end
      latest_prereq = @prerequisites.collect{|n| Rake::Task[n].timestamp}.max
      result <<  "latest-prerequisite time: #{latest_prereq}\n"
      result << "................................\n\n"
      return result
    end
    
    # Rake Module Methods ----------------------------------------------
    
    class << self
      
      # Clear the task list.  This cause rake to immediately forget all
      # the tasks that have been assigned.  (Normally used in the unit
      # tests.)
      def clear
	TASKS.clear
	RULES.clear
      end
      
      # List of all defined tasks.
      def tasks
	TASKS.keys.sort.collect { |tn| Rake::Task[tn] }
      end
      
      # Return a task with the given name.  If the task is not currently
      # known, try to synthesize one from the defined rules.  If no
      # rules are found, but an existing file matches the task name,
      # assume it is a file task with no dependencies or actions.
      def [](task_name)
	task_name = task_name.to_s
	if task = TASKS[task_name]
	  return task
	end
	if task = enhance_with_matching_rule(task_name)
	  return task
	end
	if File.exist?(task_name)
	  return Rake::FileTask.define_task(task_name)
	end
	fail "Don't know how to build task '#{task_name}'"
      end
      
      # TRUE if the task name is already defined.
      def task_defined?(task_name)
	task_name = task_name.to_s
	TASKS[task_name]
      end
      
      # Define a task given +args+ and an option block.  If a rule with
      # the given name already exists, the prerequisites and actions are
      # added to the existing task.  Returns the defined task.
      def define_task(args, &block)
	task_name, deps = resolve_args(args)
	deps = [deps] if (Symbol === deps) || (String === deps)
	deps = deps.collect {|d| d.to_s }
	t = lookup(task_name)
	t.add_comment($last_comment)
	t.enhance(deps, &block)
      end
      
      # Define a rule for synthesizing tasks.  
      def create_rule(args, &block)
	pattern, deps = resolve_args(args)
	fail "Too many dependents specified in rule #{pattern}: #{deps.inspect}" if deps.size > 1
	pattern = Regexp.new(Regexp.quote(pattern) + '$') if String === pattern
	RULES << [pattern, deps, block]
      end
      
      
      # Lookup a task.  Return an existing task if found, otherwise
      # create a task of the current type.
      def lookup(task_name)
	name = task_name.to_s
	TASKS[name] ||= self.new(task_name)
      end
      
      # If a rule can be found that matches the task name, enhance the
      # task with the prerequisites and actions from the rule.  Set the
      # source attribute of the task appropriately for the rule.  Return
      # the enhanced task or nil of no rule was found.
      def enhance_with_matching_rule(task_name, level=0)
	fail Rake::RuleRecursionOverflowError,
	  "Rule Recursion Too Deep" if level >= 16
	RULES.each do |pattern, extensions, block|
	  if md = pattern.match(task_name)
	    ext = extensions.first
	    case ext
	    when String
	      source = task_name.sub(/\.[^.]*$/, ext)
	    when Proc
	      source = ext.call(task_name)
	    else
	      fail "Don't know how to handle rule dependent: #{ext.inspect}"
	    end
	    if File.exist?(source) || Rake::Task.task_defined?(source)
	      task = FileTask.define_task({task_name => [source]}, &block)
	      task.source = source
	      return task
	    elsif parent = enhance_with_matching_rule(source, level+1)
	      task = FileTask.define_task({task_name => [parent.name]}, &block)
	      task.source = parent.name
	      return task
	    end
	  end
	end
	nil
      rescue Rake::RuleRecursionOverflowError => ex
	ex.add_target(task_name)
	fail ex
      end
      
      private 
      
      # Resolve the arguments for a task/rule.
      def resolve_args(args)
	case args
	when Hash
	  fail "Too Many Task Names: #{args.keys.join(' ')}" if args.size > 1
	  fail "No Task Name Given" if args.size < 1
	  task_name = args.keys[0]
	  deps = args[task_name]
	  deps = [deps] if (String===deps) || (Regexp===deps) || (Proc===deps)
	else
	  task_name = args
	  deps = []
	end
	[task_name, deps]
      end
    end
  end
  
  
  ######################################################################
  # A FileTask is a task that includes time based dependencies.  If
  # any of a FileTask's prerequisites have a timestamp that is later
  # than the file represented by this task, then the file must be
  # rebuilt (using the supplied actions).
  #
  class FileTask < Task
    
    # Is this file task needed?  Yes if it doesn't exist, or if its time
    # stamp is out of date.
    def needed?
      return true unless File.exist?(name)
      latest_prereq = @prerequisites.collect{|n| Rake::Task[n].timestamp}.max
      return false if latest_prereq.nil?
      timestamp < latest_prereq
    rescue Errno::ENOENT => ex # one of the prereqs does not exist
      raise unless $dryrun or $trace
      true
    end
    
    # Time stamp for file task.
    def timestamp
      File.mtime(name.to_s)
    end
  end
  
  ######################################################################
  # A FileCreationTask is a file task that when used as a dependency
  # will be needed if and only if the file has not been created.  Once
  # created, it is not re-triggered if any of its dependencies are
  # newer, nor does trigger any rebuilds of tasks that depend on it
  # whenever it is updated.
  class FileCreationTask < FileTask
    # Is this file task needed?  Yes if it doesn't exist.
    def needed?
      ! File.exist?(name)
    end
    
    # Time stamp for file creation task.  This time stamp is earlier
    # than any other time stamp.
    def timestamp
      Rake::EARLY
    end
  end
end

######################################################################
# Task Definition Functions ...

# Declare a basic task.
#
# Example:
#   task :clobber => [:clean] do
#     rm_rf "html"
#   end
#
def task(args, &block)
  Rake::Task.define_task(args, &block)
end


# Declare a file task.
#
# Example:
#   file "config.cfg" => ["config.template"] do
#     open("config.cfg", "w") do |outfile|
#       open("config.template") do |infile|
#         while line = infile.gets
#           outfile.puts line
#         end
#       end
#     end
#  end
#
def file(args, &block)
  Rake::FileTask.define_task(args, &block)
end

# Declare a file creation task.
# (Mainly used for the directory command).
def file_create(args, &block)
  Rake::FileCreationTask.define_task(args, &block)
end

# Declare a set of files tasks to create the given directories on
# demand.
#
# Example:
#   directory "testdata/doc"
#
def directory(dir)
  Rake.each_dir_parent(dir) do |d|
    file_create d do |t|
      mkdir_p t.name if ! File.exist?(t.name)
    end
  end
end

# Declare a rule for auto-tasks.
#
# Example:
#  rule '.o' => '.c' do |t|
#    sh %{cc -o #{t.name} #{t.source}}
#  end
#
def rule(args, &block)
  Rake::Task.create_rule(args, &block)
end

# Describe the next rake task.
#
# Example:
#   desc "Run the Unit Tests"
#   task :test => [:build]
#     runtests
#   end
#
def desc(comment)
  $last_comment = comment
end

# Import the partial Rakekfile +fn+.
#
# Example:
#   import ".depend"
#
def import(fn)
  Rake.application.add_import(fn)
end

######################################################################
# This a FileUtils extension that defines several additional commands
# to be added to the FileUtils utility functions.
#
module FileUtils
  RUBY = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])

  OPT_TABLE['sh']  = %w(noop verbose)
  OPT_TABLE['ruby'] = %w(noop verbose)

  # Run the system command +cmd+. If multiple arguments are given
  # the command is not run with the shell (same semantics as
  # Kernel::exec and Kernel::system).
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
    if Hash === cmd.last then
      options = cmd.pop
    else
      options = {}
    end
    unless block_given?
      show_command = cmd.join(" ")
      show_command = show_command[0,42] + "..." if show_command.length > 45
      block = lambda { |ok, status|
        ok or fail "Command failed with status (#{status.exitstatus}): [#{show_command}]"
      }
    end
    fu_check_options options, :noop, :verbose
    fu_output_message cmd.join(" ") if options[:verbose]
    unless options[:noop]
      res = system(*cmd)      
      block.call(res, $?)
    end
  end

  # Run a Ruby interpreter with the given arguments.
  #
  # Example:
  #   ruby %{-pe '$_.upcase!' <README}
  #
  def ruby(*args,&block)
    if Hash === args.last
      options = args.pop
    else
      options = {}
    end
    if args.length > 1 then
      sh(*([RUBY] + args + [options]), &block)
    else
      sh("#{RUBY} #{args}", options, &block)
    end
  end
  
  LN_SUPPORTED = [true]

  #  Attempt to do a normal file link, but fall back to a copy if the
  #  link fails.
  def safe_ln(*args)
    unless LN_SUPPORTED[0]
      cp(*args)
    else
      begin
        ln(*args)
      rescue Errno::EOPNOTSUPP
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

######################################################################
# RakeFileUtils provides a custom version of the FileUtils methods
# that respond to the <tt>verbose</tt> and <tt>nowrite</tt> commands.
#
module RakeFileUtils
  include FileUtils
  
  $fileutils_output  = $stderr
  $fileutils_label   = ''
  $fileutils_verbose = true
  $fileutils_nowrite = false
  
  FileUtils::OPT_TABLE.each do |name, opts|
    next unless opts.include?('verbose')
    module_eval(<<-EOS, __FILE__, __LINE__ + 1)
    def #{name}( *args, &block )
      super(*fu_merge_option(args,
          :verbose => $fileutils_verbose,
          :noop => $fileutils_nowrite),
        &block)
    end
    EOS
  end

  # Get/set the verbose flag controlling output from the FileUtils
  # utilities.  If verbose is true, then the utility method is echoed
  # to standard output.
  #
  # Examples:
  #    verbose              # return the current value of the verbose flag
  #    verbose(v)           # set the verbose flag to _v_.
  #    verbose(v) { code }  # Execute code with the verbose flag set temporarily to _v_.
  #                         # Return to the original value when code is done.
  def verbose(value=nil)
    oldvalue = $fileutils_verbose
    $fileutils_verbose = value unless value.nil?
    if block_given?
      begin
        yield
      ensure
        $fileutils_verbose = oldvalue
      end
    end
    $fileutils_verbose
  end

  # Get/set the nowrite flag controlling output from the FileUtils
  # utilities.  If verbose is true, then the utility method is echoed
  # to standard output.
  #
  # Examples:
  #    nowrite              # return the current value of the nowrite flag
  #    nowrite(v)           # set the nowrite flag to _v_.
  #    nowrite(v) { code }  # Execute code with the nowrite flag set temporarily to _v_.
  #                         # Return to the original value when code is done.
  def nowrite(value=nil)
    oldvalue = $fileutils_nowrite
    $fileutils_nowrite = value unless value.nil?
    if block_given?
      begin
        yield
      ensure
        $fileutils_nowrite = oldvalue
      end
    end
    oldvalue
  end

  # Use this function to prevent protentially destructive ruby code
  # from running when the :nowrite flag is set.
  #
  # Example: 
  #
  #   when_writing("Building Project") do
  #     project.build
  #   end
  #
  # The following code will build the project under normal conditions.
  # If the nowrite(true) flag is set, then the example will print:
  #      DRYRUN: Building Project
  # instead of actually building the project.
  #
  def when_writing(msg=nil)
    if $fileutils_nowrite
      puts "DRYRUN: #{msg}" if msg
    else
      yield
    end
  end

  # Merge the given options with the default values.
  def fu_merge_option(args, defaults)
    if Hash === args.last
      defaults.update(args.last)
      args.pop
    end
    args.push defaults
    args
  end
  private :fu_merge_option

  extend self
  
end

######################################################################
# Include the FileUtils file manipulation functions in the top level
# module, but mark them private so that they don't unintentionally
# define methods on other objects.

include RakeFileUtils
private(*FileUtils.instance_methods(false))

######################################################################
module Rake

  class RuleRecursionOverflowError < StandardError
    def initialize(*args)
      super
      @targets = []
    end

    def add_target(target)
      @targets << target
    end

    def message
      super + ": [" + @targets.reverse.join(' => ') + "]"
    end
  end

  ####################################################################
  # A FileList is essentially an array with a few helper methods
  # defined to make file manipulation a bit easier.
  #
  # FileLists are lazy.  When given a list of glob patterns for
  # possible files to be included in the file list, instead of
  # searching the file structures to find the files, a FileList holds
  # the pattern for latter use.
  #
  # This allows us to define a number of FileList to match any number of
  # files, but only search out the actual files when then FileList
  # itself is actually used.  The key is that the first time an
  # element of the FileList/Array is requested, the pending patterns
  # are resolved into a real list of file names.
  #
  class FileList 

    include Cloneable

    # == Method Delegation
    #
    # The lazy evaluation magic of FileLists happens by implementing
    # all the array specific methods to call +resolve+ before
    # delegating the heavy lifting to an embedded array object
    # (@items).
    #
    # In addition, there are two kinds of delegation calls.  The
    # regular kind delegates to the @items array and returns the
    # result directly.  Well, almost directly.  It checks if the
    # returned value is the @items object itself, and if so will
    # return the FileList object instead.
    #
    # The second kind of delegation call is used in methods that
    # normally return a new Array object.  We want to capture the
    # return value of these methods and wrap them in a new FileList
    # object.  We enumerate these methods in the +SPECIAL_RETURN+ list
    # below.

    # List of array methods (that are not in +Object+) that need to be
    # delegated.
    ARRAY_METHODS = Array.instance_methods - Object.instance_methods

    # List of additional methods that must be delegated.
    MUST_DEFINE = %w[to_a inspect]

    # List of methods that should not be delegated here (we define
    # special versions of them explicitly below).
    MUST_NOT_DEFINE = %w[to_a to_ary partition *]

    # List of delegated methods that return new array values which
    # need wrapping.
    SPECIAL_RETURN = %w[
      map collect sort sort_by select find_all reject grep
      compact flatten uniq values_at
      + - & |
    ]
    
    DELEGATING_METHODS = (ARRAY_METHODS + MUST_DEFINE - MUST_NOT_DEFINE).sort.uniq
    
    # Now do the delegation.
    DELEGATING_METHODS.each_with_index do |sym, i|
      if SPECIAL_RETURN.include?(sym)
        ln = __LINE__+1
        class_eval %{
          def #{sym}(*args, &block)
            resolve if @pending
            result = @items.send(:#{sym}, *args, &block)
            FileList.new.import(result)
          end
        }, __FILE__, ln
      else
        ln = __LINE__+1
        class_eval %{
          def #{sym}(*args, &block)
            resolve if @pending
            result = @items.send(:#{sym}, *args, &block)
            result.object_id == @items.object_id ? self : result
          end
        }, __FILE__, ln
      end
    end

    # Create a file list from the globbable patterns given.  If you
    # wish to perform multiple includes or excludes at object build
    # time, use the "yield self" pattern.
    #
    # Example:
    #   file_list = FileList.new['lib/**/*.rb', 'test/test*.rb']
    #
    #   pkg_files = FileList.new['lib/**/*'] do |fl|
    #     fl.exclude(/\bCVS\b/)
    #   end
    #
    def initialize(*patterns)
      @pending_add = []
      @pending = false
      @exclude_patterns = DEFAULT_IGNORE_PATTERNS.dup
      @exclude_re = nil
      @items = []
      patterns.each { |pattern| include(pattern) }
      yield self if block_given?
    end

    # Add file names defined by glob patterns to the file list.  If an
    # array is given, add each element of the array.
    #
    # Example:
    #   file_list.include("*.java", "*.cfg")
    #   file_list.include %w( math.c lib.h *.o )
    #
    def include(*filenames)
      # TODO: check for pending
      filenames.each do |fn|
	if fn.respond_to? :to_ary
	  include(*fn.to_ary)
	else
	  @pending_add << fn
	end
      end
      @pending = true
      self
    end
    alias :add :include 
    
    # Register a list of file name patterns that should be excluded
    # from the list.  Patterns may be regular expressions, glob
    # patterns or regular strings.
    #
    # Note that glob patterns are expanded against the file system.
    # If a file is explicitly added to a file list, but does not exist
    # in the file system, then an glob pattern in the exclude list
    # will not exclude the file.
    #
    # Examples:
    #   FileList['a.c', 'b.c'].exclude("a.c") => ['b.c']
    #   FileList['a.c', 'b.c'].exclude(/^a/)  => ['b.c']
    #
    # If "a.c" is a file, then ...
    #   FileList['a.c', 'b.c'].exclude("a.*") => ['b.c']
    #
    # If "a.c" is not a file, then ...
    #   FileList['a.c', 'b.c'].exclude("a.*") => ['a.c', 'b.c']
    #
    def exclude(*patterns)
      patterns.each do |pat| @exclude_patterns << pat end
      if ! @pending
        calculate_exclude_regexp
        reject! { |fn| fn =~ @exclude_re }
      end
      self
    end

    
    # Clear all the exclude patterns so that we exclude nothing.
    def clear_exclude
      @exclude_patterns = []
      calculate_exclude_regexp if ! @pending
    end

    # Define equality.
    def ==(array)
      to_ary == array
    end

    # Return the internal array object.
    def to_a
      resolve
      @items
    end

    # Return the internal array object.
    def to_ary
      resolve
      @items
    end

    # Redefine * to return either a string or a new file list.
    def *(other)
      result = @items * other
      case result
      when Array
	FileList.new.import(result)
      else
	result
      end
    end

    # Resolve all the pending adds now.
    def resolve
      if @pending
        @pending = false
        @pending_add.each do |fn| resolve_add(fn) end
        @pending_add = []
        resolve_exclude
      end
      self
    end

    def calculate_exclude_regexp
      ignores = []
      @exclude_patterns.each do |pat|
        case pat
        when Regexp
          ignores << pat
        when /[*.]/
          Dir[pat].each do |p| ignores << p end
        else
          ignores << Regexp.quote(pat)
        end
      end
      if ignores.empty?
        @exclude_re = /^$/
      else
        re_str = ignores.collect { |p| "(" + p.to_s + ")" }.join("|")
        @exclude_re = Regexp.new(re_str)
      end
    end

    def resolve_add(fn)
      case fn
      when Array
        fn.each { |f| self.resolve_add(f) }
      when %r{[*?]}
        add_matching(fn)
      else
        self << fn
      end
    end

    def resolve_exclude
      @exclude_patterns.each do |pat|
        case pat
        when Regexp
          reject! { |fn| fn =~ pat }
        when /[*.]/
          reject_list = Dir[pat]
          reject! { |fn| reject_list.include?(fn) }
        else
          reject! { |fn| fn == pat }
        end
      end
      self
    end

    # Return a new FileList with the results of running +sub+ against
    # each element of the oringal list.
    #
    # Example:
    #   FileList['a.c', 'b.c'].sub(/\.c$/, '.o')  => ['a.o', 'b.o']
    #
    def sub(pat, rep)
      inject(FileList.new) { |res, fn| res << fn.sub(pat,rep) }
    end

    # Return a new FileList with the results of running +gsub+ against
    # each element of the original list.
    #
    # Example:
    #   FileList['lib/test/file', 'x/y'].gsub(/\//, "\\")
    #      => ['lib\\test\\file', 'x\\y']
    #
    def gsub(pat, rep)
      inject(FileList.new) { |res, fn| res << fn.gsub(pat,rep) }
    end

    # Same as +sub+ except that the oringal file list is modified.
    def sub!(pat, rep)
      each_with_index { |fn, i| self[i] = fn.sub(pat,rep) }
      self
    end

    # Same as +gsub+ except that the original file list is modified.
    def gsub!(pat, rep)
      each_with_index { |fn, i| self[i] = fn.gsub(pat,rep) }
      self
    end

    # Return a new array with <tt>String#ext</tt> method applied to
    # each member of the array.
    #
    # This method is a shortcut for:
    #
    #    array.collect { |item| item.ext(newext) }
    #
    # +ext+ is a user added method for the Array class.
    def ext(newext='')
      collect { |fn| fn.ext(newext) }
    end


    # Grep each of the files in the filelist using the given pattern.
    # If a block is given, call the block on each matching line,
    # passing the file name, line number, and the matching line of
    # text.  If no block is given, a standard emac style
    # file:linenumber:line message will be printed to standard out.
    def egrep(pattern)
      each do |fn|
	open(fn) do |inf|
	  count = 0
	  inf.each do |line|
	    count += 1
	    if pattern.match(line)
	      if block_given?
		yield fn, count, line
	      else
		puts "#{fn}:#{count}:#{line}"
	      end		
	    end
	  end
	end
      end
    end

    # FileList version of partition.  Needed because the nested arrays
    # should be FileLists in this version.
    def partition(&block)	# :nodoc:
      resolve
      result = @items.partition(&block)
      [
        FileList.new.import(result[0]),
        FileList.new.import(result[1]),
      ]
    end
    
    # Convert a FileList to a string by joining all elements with a space.
    def to_s
      resolve if @pending
      self.join(' ')
    end

    # Add matching glob patterns.
    def add_matching(pattern)
      Dir[pattern].each do |fn|
        self << fn unless exclude?(fn)
      end
    end
    private :add_matching

    # Should the given file name be excluded?
    def exclude?(fn)
      calculate_exclude_regexp unless @exclude_re
      fn =~ @exclude_re
    end

    DEFAULT_IGNORE_PATTERNS = [
      /(^|[\/\\])CVS([\/\\]|$)/,
      /(^|[\/\\])\.svn([\/\\]|$)/,
      /\.bak$/,
      /~$/,
      /(^|[\/\\])core$/
    ]
    @exclude_patterns = DEFAULT_IGNORE_PATTERNS.dup

    def import(array)
      @items = array
      self
    end

    class << self
      # Create a new file list including the files listed. Similar to:
      #
      #   FileList.new(*args)
      def [](*args)
        new(*args)
      end

      # Set the ignore patterns back to the default value.  The
      # default patterns will ignore files 
      # * containing "CVS" in the file path
      # * containing ".svn" in the file path
      # * ending with ".bak"
      # * ending with "~"
      # * named "core"
      #
      # Note that file names beginning with "." are automatically
      # ignored by Ruby's glob patterns and are not specifically
      # listed in the ignore patterns.
      def select_default_ignore_patterns
        @exclude_patterns = DEFAULT_IGNORE_PATTERNS.dup
      end

      # Clear the ignore patterns.  
      def clear_ignore_patterns
        @exclude_patterns = [ /^$/ ]
      end
    end
  end # FileList
end

module Rake
  class << self

    # Yield each file or directory component.
    def each_dir_parent(dir)
      old_length = nil
      while dir != '.' && dir.length != old_length
	yield(dir)
	old_length = dir.length
	dir = File.dirname(dir)
      end
    end
  end
end

# Alias FileList to be available at the top level.
FileList = Rake::FileList

######################################################################
module Rake

  # Default Rakefile loader used by +import+.
  class DefaultLoader
    def load(fn)
      Kernel.load fn
    end
  end

  # EarlyTime is a fake timestamp that occurs _before_ any other time
  # value.
  class EarlyTime
    include Comparable
    include Singleton

    def <=>(other)
      -1
    end

    def to_s
      "<EARLY TIME>"
    end
  end

  EARLY = EarlyTime.instance
end

######################################################################
# Extensions to time to allow comparisons with an early time class.
class Time
  alias pre_early_time_compare :<=>
  def <=>(other)
    if Rake::EarlyTime === other
      - other.<=>(self)
    else
      pre_early_time_compare(other)
    end
  end     
end

######################################################################
# Rake main application object.  When invoking +rake+ from the command
# line, a RakeApp object is created and run.
#
class RakeApp
  RAKEFILES = ['rakefile', 'Rakefile', 'rakefile.rb', 'Rakefile.rb']

  OPTIONS = [
    ['--dry-run',  '-n', GetoptLong::NO_ARGUMENT,
      "Do a dry run without executing actions."],
    ['--help',     '-H', GetoptLong::NO_ARGUMENT,
      "Display this help message."],
    ['--libdir',   '-I', GetoptLong::REQUIRED_ARGUMENT,
      "Include LIBDIR in the search path for required modules."],
    ['--nosearch', '-N', GetoptLong::NO_ARGUMENT,
      "Do not search parent directories for the Rakefile."],
    ['--prereqs',  '-P', GetoptLong::NO_ARGUMENT,
      "Display the tasks and dependencies, then exit."],
    ['--quiet',    '-q', GetoptLong::NO_ARGUMENT,
      "Do not log messages to standard output."],
    ['--rakefile', '-f', GetoptLong::REQUIRED_ARGUMENT,
      "Use FILE as the rakefile."],
    ['--require',  '-r', GetoptLong::REQUIRED_ARGUMENT,
      "Require MODULE before executing rakefile."],
    ['--silent',   '-s', GetoptLong::NO_ARGUMENT,
      "Like --quiet, but also suppresses the 'in directory' announcement."],
    ['--tasks',    '-T', GetoptLong::NO_ARGUMENT,
      "Display the tasks and dependencies, then exit."],
    ['--trace',    '-t', GetoptLong::NO_ARGUMENT,
      "Turn on invoke/execute tracing, enable full backtrace."],
    ['--usage',    '-h', GetoptLong::NO_ARGUMENT,
      "Display usage."],
    ['--verbose',  '-v', GetoptLong::NO_ARGUMENT,
      "Log message to standard output (default)."],
    ['--version',  '-V', GetoptLong::NO_ARGUMENT,
      "Display the program version."],
    ['--classic-namespace', '-C', GetoptLong::NO_ARGUMENT,
      "Put Task and FileTask in the top level namespace"],
  ]

  # Create a RakeApp object.
  def initialize
    @rakefile = nil
    @pending_imports = []
    @imported = []
    @nosearch = false
    @loaders = {}
    @default_loader = Rake::DefaultLoader.new
    Rake.application = self
  end

  # True if one of the files in RAKEFILES is in the current directory.
  # If a match is found, it is copied into @rakefile.
  def have_rakefile
    RAKEFILES.each do |fn|
      if File.exist?(fn)
        @rakefile = fn
        return true
      end
    end
    return false
  end

  # Display the program usage line.
  def usage
    puts "rake [-f rakefile] {options} targets..."
  end

  # Display the rake command line help.
  def help
    usage
    puts
    puts "Options are ..."
    puts
    OPTIONS.sort.each do |long, short, mode, desc|
      if mode == GetoptLong::REQUIRED_ARGUMENT
        if desc =~ /\b([A-Z]{2,})\b/
          long = long + "=#{$1}"
        end
      end
      printf "  %-20s (%s)\n", long, short
      printf "      %s\n", desc
    end
  end

  # Display the tasks and dependencies.
  def display_tasks_and_comments
    width = Rake::Task.tasks.select { |t|
      t.comment
    }.collect { |t|
      t.name.length
    }.max
    Rake::Task.tasks.each do |t|
      if t.comment
        printf "rake %-#{width}s  # %s\n", t.name, t.comment
      end
    end
  end

  # Display the tasks and prerequisites
  def display_prerequisites
    Rake::Task.tasks.each do |t|
      puts "rake #{t.name}"
      t.prerequisites.each { |pre| puts "    #{pre}" }
    end
  end

  # Return a list of the command line options supported by the
  # program.
  def command_line_options
    OPTIONS.collect { |lst| lst[0..-2] }
  end

  # Do the option defined by +opt+ and +value+.
  def do_option(opt, value)
    case opt
    when '--dry-run'
      verbose(true)
      nowrite(true)
      $dryrun = true
      $trace = true
    when '--help'
      help
      exit
    when '--libdir'
      $:.push(value)
    when '--nosearch'
      @nosearch = true
    when '--prereqs'
      $show_prereqs = true
    when '--quiet'
      verbose(false)
    when '--rakefile'
      RAKEFILES.clear
      RAKEFILES << value
    when '--require'
      require value
    when '--silent'
      verbose(false)
      $silent = true
    when '--tasks'
      $show_tasks = true
    when '--trace'
      $trace = true
      verbose(true)
    when '--usage'
      usage
      exit
    when '--verbose'
      verbose(true)
    when '--version'
      puts "rake, version #{RAKEVERSION}"
      exit
    when '--classic-namespace'
      require 'rake/classic_namespace'
    else
      fail "Unknown option: #{opt}"
    end
  end
  
  # Read and handle the command line options.
  def handle_options
    opts = GetoptLong.new(*command_line_options)
    opts.each { |opt, value| do_option(opt, value) }
  end

  def load_rakefile
    here = Dir.pwd
    while ! have_rakefile
      Dir.chdir("..")
      if Dir.pwd == here || @nosearch
        fail "No Rakefile found (looking for: #{RAKEFILES.join(', ')})"
      end
      here = Dir.pwd
    end
    puts "(in #{Dir.pwd})" unless $silent
    $rakefile = @rakefile
    load @rakefile
    load_imports
  end

  # Collect the list of tasks on the command line.  If no tasks are
  # give, return a list containing only the default task.
  # Environmental assignments are processed at this time as well.
  def collect_tasks
    tasks = []
    ARGV.each do |arg|
      if arg =~ /^(\w+)=(.*)$/
        ENV[$1] = $2
      else
        tasks << arg
      end
    end
    tasks.push("default") if tasks.size == 0
    tasks
  end

  # Add a file to the list of files to be imported.
  def add_import(fn)
    @pending_imports << fn
  end

  # Load the pending list of imported files.
  def load_imports
    while fn = @pending_imports.shift
      next if @imported.member?(fn)
      Rake::Task[fn].invoke if Rake::Task.task_defined?(fn)
      ext = File.extname(fn)
      loader = @loaders[ext] || @default_loader
      loader.load(fn)
      @imported << fn
    end
  end

  # Add a loader to handle imported files ending in the extension
  # +ext+.
  def add_loader(ext, loader)
    ext = ".#{ext}" unless ext =~ /^\./
    @loaders[ext] = loader
  end

  # Run the +rake+ application.
  def run
    handle_options
    begin
      tasks = collect_tasks
      load_rakefile
      if $show_tasks
        display_tasks_and_comments
      elsif $show_prereqs
        display_prerequisites
      else
        tasks.each { |task_name| Rake::Task[task_name].invoke }
      end
    rescue Exception => ex
      puts "rake aborted!"
      puts ex.message
      if $trace
        puts ex.backtrace.join("\n")
      else
        puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
      end
      exit(1)
    end    
  end
end

if __FILE__ == $0 then
  RakeApp.new.run
end
