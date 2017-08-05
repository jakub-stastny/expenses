require 'expenses/models/loggable_item'

module Expenses
  class BaseExpense < LoggableItem
    self.private_attributes = [:total_usd, :total_eur]

    def initialize(date:, location:, currency:, payment_method:, note: nil, total_usd: nil, total_eur: nil)
      @date     = validate_date(date)
      @currency = validate_currency(currency)
      @note     = note
      @location = location
      @payment_method = payment_method

      @total_usd = if total_usd then validate_amount_in_cents(total_usd)
      elsif @currency == 'USD' then @total
      else convert_currency(@total, @currency, 'USD') end

      @total_eur = if total_eur then validate_amount_in_cents(total_eur)
      elsif @currency == 'EUR' then @total
      else convert_currency(@total, @currency, 'EUR') end
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  # Fee: if it's not cash, then (how much disapeared from my account) - expense.total.
  class Expense < BaseExpense
    def initialize(date:, desc:, tip: 0, location:, currency:, note: nil, tag:,
      payment_method:, vale_la_pena: nil, fee: 0, items: Array.new,
      total_usd: nil, total_eur: nil)

      @desc = validate_desc(desc)
      @tip  = validate_amount_in_cents(tip)
      @tag  = validate_tag(tag) if tag && ! tag.empty?
      @vale_la_pena = validate_integer(vale_la_pena) if vale_la_pena
      @fee  = validate_amount_in_cents(fee) if fee
      @items = items

      super(date: date, location: location,
        currency: currency, payment_method: payment_method,
        note: note, total_usd: total_usd, total_eur: total_eur)
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end

    def total
      self.items.sum(&:total) + self.tip + self.fee
    end
  end

  class UnknownExpense < BaseExpense
    def initialize(date:, total:, location:, currency:, payment_method:, note: nil, total_usd: nil, total_eur: nil)
      @total = validate_amount_in_cents(total)
      super(date, location, currency, payment_method, note, total_usd, total_eur)
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end

    def desc
      'Unknown expense.'
    end

    def items
      [Item.new(total: self.total, desc: self.desc)]
    end
  end
end
