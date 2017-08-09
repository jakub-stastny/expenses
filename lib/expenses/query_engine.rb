require 'date'

module Expenses
  class QueryEngine
    def initialize(collection)
      @collection = collection
    end

    def tags
      items = @collection.expenses.map(&:items).flatten
      self.attribute_values_with_counts(items).map(&:first)
    end

    def attribute_values_with_counts(list, attribute = :tag)
      attributes_with_counts = list.reduce(Hash.new) do |buffer, item|
        buffer[item.send(attribute)] ||= 0
        buffer[item.send(attribute)] += 1
        buffer
      end

      attributes_with_counts.sort_by { |(_, count)| count }.reverse
    end

    def days_expenses(day = Date.today)
      @collection.expenses.select do |expense|
        expense.date == day
      end
    end

    def days_items(day = Date.today)
      self.days_expenses(day).map(&:items).flatten
    end
  end
end
