require 'expenses/models/loggable_item'

module Expenses
  class Income < LoggableItem
    def initialize(date:, total:, account:, fee: nil)
      @date    = validate_date(date)
      @total   = validate_amount_in_cents(total)
      @account = account
      @fee     = validate_amount_in_cents(fee) if fee
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
