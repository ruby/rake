module Rake
  class Scope < LinkedList

    def path
      map { |item| item.to_s }.reverse.join(":")
    end

    def path_with_task_name(task_name)
      "#{path}:#{task_name}"
    end

    class EmptyScope < EmptyLinkedList
      def path
        ""
      end

      def path_with_task_name(task_name)
        task_name
      end
    end

    EMPTY = EmptyScope.new(self)
  end
end
