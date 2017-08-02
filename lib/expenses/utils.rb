module Expenses
  module Utils
    def self.balance_for(collection, expense)
      type = expense.payment_method == 'cash' ? :withdrawal : :balance
      last_item_with_balance = collection.items.reverse.find do |item|
        item.type == type && item.currency == expense.currency
      end

      return if last_item_with_balance.nil?

      unless last_item_with_balance.balance
        raise "#{last_item_with_balance.inspect} doesn't have balance"
      end

      index = collection.items.index(last_item_with_balance)
      current_expenses = collection.items[index..-1].select do |item|
        item.type == :expense && item.payment_method == expense.payment_method
      end

      last_item_with_balance.balance - current_expenses.sum(&:total)
    end
  end
end
