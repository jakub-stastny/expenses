# frozen_string_literal: true

require 'expenses/models/loggable_item'

module Expenses
  # Whether it's meant to be returned (flat deposit) or not (tailor).
  class Deposit < LoggableItem
    def initialize(date:, desc:, total:, currency:, payment_method:, expiration_date: , status: 'open', note: nil)
      @date     = validate_date(date)
      @desc     = validate_desc(desc)
      @total    = validate_amount_in_cents(total) # Including tip.
      @currency = validate_currency(currency)
      @payment_method = payment_method
      @expiration_date = validate_date(expiration_date)
      @status   = status
      @note     = note
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
