require 'expenses/models/loggable_item'

module Expenses
  # Should refer to an ID (index?).
  # Fee is (money sent) - (money received) for complete refunds.
  # Refunds can be partial as well though.
  class Refund < LoggableItem
    def initialize(date:, note: nil, fee: nil)
      @date = validate_date(date)
      @note = note
      @fee  = validate_amount_in_cents(fee) if fee
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
