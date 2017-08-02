module Expenses
  module Utils
    def self.balance_for(collection, payment_method, currency = nil)
      if payment_method == 'cash'
        last_item_with_balance = self.find_last_item_with_balance_for_cash(collection, currency)
      else
        last_item_with_balance = self.find_last_item_with_balance_for_account(collection, payment_method)
      end

      return if last_item_with_balance.nil?

      unless last_item_with_balance.balance
        raise "#{last_item_with_balance.inspect} doesn't have balance"
      end

      index = collection.items.index(last_item_with_balance)
      current_expenses = collection.items[index..-1].select do |item|
        item.type == :expense && item.payment_method == payment_method
      end

      last_item_with_balance.balance - current_expenses.sum(&:total)
    end

    def self.find_last_item_with_balance_for_cash(collection, currency)
      last_item_with_balance = collection.items.reverse.find do |item|
        item.type == :withdrawal && item.currency == currency
      end
    end

    def self.find_last_item_with_balance_for_account(collection, payment_method)
      # account_name = payment_method.split(' ')[0..-2].join(' ')
      account_name = payment_method
      last_item_with_balance = collection.items.reverse.find do |item|
        item.type == :balance && item.account == account_name
      end
    end

    def self.format_cents_to_money(cents)
      groups = cents.to_s.each_char.group_by.with_index do |char, index|
        index < (cents.to_s.length - 2)
      end

      x = (groups[true] || ['0']).join
      y = groups[false].join unless groups[false].join.match(/^0{1,2}$/)
      [x, y].compact.join('.')
    end
  end
end
