require 'expenses/models/loggable_item'

module Expenses
  class Withdrawal < LoggableItem
    def initialize(date:, total:, currency:, account:, location:, balance:, note: nil, fee: nil)
      @date     = validate_date(date)
      @total    = validate_amount_in_cents(total)
      @currency = validate_currency(currency)
      @account  = account
      @location = location
      @balance  = validate_amount_in_cents(balance)
      @note     = note
      @fee      = validate_amount_in_cents(fee) if fee
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
