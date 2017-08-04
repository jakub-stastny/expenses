require 'expenses/loggable_item'

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

  class BaseExpense < LoggableItem
    self.private_attributes = [:total_usd, :total_eur]

    def initialize(date:, total:, location:, currency:, payment_method:, note: nil, total_usd: nil, total_eur: nil)
      @date     = validate_date(date)
      @total    = validate_amount_in_cents(total) # Including tip.
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
    VALE_LA_PENA_LABELS = ['yes', 'no', 'good, but too expensive']

    def initialize(date:, desc:, total:, tip: 0, location:, currency:, note: nil, tag: nil, payment_method:, vale_la_pena: nil, fee: nil, items: Array.new, total_usd: nil, total_eur: nil)
      @desc = validate_desc(desc)
      @tip  = validate_amount_in_cents(tip)
      @tag  = validate_tag(tag) if tag && ! tag.empty?
      @vale_la_pena = validate_integer(vale_la_pena) if vale_la_pena
      @fee  = validate_amount_in_cents(fee) if fee
      @items = items

      super(date: date, total: total, location: location,
        currency: currency, payment_method: payment_method,
        note: note, total_usd: total_usd, total_eur: total_eur)
    end

    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  class UnknownExpense < BaseExpense
    def desc
      'Unknown expense.'
    end
  end
end
