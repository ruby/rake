#!/usr/bin/env ruby

module Rake

  class TaskLib
    def clone
      sibling = self.class.new
      instance_variables.each do |ivar|
	value = self.instance_variable_get(ivar)
	sibling.instance_variable_set(ivar, value.dup) if value
      end
      sibling
    end
  end

end
