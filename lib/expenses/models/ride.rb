# frozen_string_literal: true

require 'expenses/models/loggable_item'

module Expenses
  # Don't forget to reset the trip before you go.
  class Ride < LoggableItem
    def initialize(date:, car:, distance:, where:, note: nil)
      @date     = validate_date(date)
      @car      = car
      @distance = validate_amount_in_cents(distance)
      @where    = where
      @note     = note
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
