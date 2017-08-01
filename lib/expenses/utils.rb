module Expenses
  module Utils
    def self.running_total_for(collection, expense)
      type = expense.payment_method == 'cash' ? :withdrawal : :review
      last_item_with_running_total = collection.items.reverse.find do |item|
        item.type == type && item.currency == expense.currency
      end

      return if last_item_with_running_total.nil?

      unless last_item_with_running_total.running_total
        raise "#{last_item_with_running_total.inspect} doesn't have running_total"
      end

      index = collection.items.index(last_item_with_running_total)
      current_expenses = collection.items[index..-1].select do |item|
        item.type == :expense && item.payment_method == expense.payment_method
      end

      last_item_with_running_total.running_total - current_expenses.sum(&:total)
    end
  end
end
