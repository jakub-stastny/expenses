# frozen_string_literal: true

require 'expenses/models/serialisable_item'

module Expenses
  class Item < SerialisableItem
    # Unless tag specified explicitly, we'll work with the expense tag instead.
    #
    # Quantity should be an integer at all times. Therefore typically grams and
    #   mililitres would be used rather than kgs and litres.
    #
    # Item.new(desc: "Maślanka naturalna", total: 215, quantity: 1000, unit: 'mililitres', count: 2)
    #   This means we bought 2 boxes of maślanka, 1 litre each.
    def initialize(desc:, total:, note: nil,
                   tag: nil, vale_la_pena: nil,
                   quantity: nil, unit: nil, count: nil)
      @desc = validate_desc(desc)
      @total = validate_amount_in_cents(total)
      @note = note
      @tag = validate_tag(tag) if tag && !tag.empty?
      @vale_la_pena = validate_vale_la_pena(vale_la_pena)
      @quantity = quantity
      @unit = unit
      @count = count if count
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
