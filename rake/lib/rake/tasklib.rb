#!/usr/bin/env ruby

module Rake

  # Base class for Task Libraries.
  class TaskLib

    # Make a copy of a task.
    def clone
      sibling = self.class.new
      instance_variables.each do |ivar|
	value = self.instance_variable_get(ivar)
	sibling.instance_variable_set(ivar, value.dup) if value
      end
      sibling
    end

    # Make a symbol by pasting two strings together. 
    def paste(a,b)
      (a.to_s + b.to_s).intern
    end
  end

end
