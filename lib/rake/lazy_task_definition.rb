# frozen_string_literal: true
module Rake

  # The LazyTaskDefinition module is a mixin for managing lazy defined tasks.
  module LazyTaskDefinition

    # Execute all definitions: usefull for rake -T for instance
    def execute_all_lazy_definitions
      lazy_definitions.each do |scope_path, _definitions|
        execute_lazy_definitions(scope_path)
      end
    end

    # Execute all definitions linked to specified +scope_path+
    # and its parent scopes.
    def execute_lazy_definitions(scope_path)
      scope_path_elements = scope_path.split(':')
      sub_scope_elements = []
      scope_path_elements.each do |e|
        sub_scope_elements << e
        sub_scope_path = sub_scope_elements.join(':')
        definitions = lazy_definitions[sub_scope_path]
        next unless definitions
        definitions.each do |definition|
          definition.call
        end
        definitions.clear
      end
    end

    # Evaluate the block in specified +scope+.
    def in_scope(scope)
      cur_scope = @scope
      @scope = scope
      yield
    ensure
      @scope = cur_scope
    end

    # Register a block which will be called only when necessary during the lookup 
    # of tasks
    def register_lazy_definition(&block)
      cur_scope = @scope
      lazy_definitions[cur_scope.path] ||= []
      lazy_definitions[cur_scope.path] << ->() { in_scope(cur_scope, &block) }
    end

    def lazy_definitions
        @lazy_definitions ||= {} 
    end
    private :lazy_definitions
  end
end