# frozen_string_literal: true

require 'expenses/models/loggable_item'

module Expenses
  class Balance < LoggableItem
    def initialize(date:, account:, balance:, note: nil)
      @date    = validate_date(date)
      @account = account
      @balance = validate_amount_in_cents(balance)
      @note    = note
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
