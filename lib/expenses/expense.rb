require 'expenses/loggable_item'

module Expenses
  # TODO: Mapping of accounts to payment methods:
  # FIO EUR -> FIO EUR VISA or something like that.
  #
  # We could even just use the bank account, but PayPal
  # breaks the 1:1 mapping.
  #
  # Also sometimes the expense actually is a bank transfer rather than a bank
  # transaction, though it's similar enough (and rare enough) that keeping it
  # together would make the payment_methods easier to work with.
  #
  # Maybe I can separate it into bank_account x payment method and have there
  # same contract as between location x currency.
  #
  # TODO: What about transfer fees? Should we log them as well.
  class Income < LoggableItem
    def initialize(date:, total:, account:)
      @date    = validate_date(date)
      @total   = validate_amount_in_cents(total)
      @account = account
    end

    # This has to be done after #initialize.
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

    # This has to be done after #initialize.
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

    # This has to be done after #initialize.
    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  class Ride < LoggableItem
    def initialize(date:, car:, distance:, where:, note: nil)
      @date     = validate_date(date)
      @car      = car
      @distance = validate_amount_in_cents(distance)
      @where    = where
      @note     = note
    end

    # This has to be done after #initialize.
    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  # Should refer to an ID (index?).
  # Can be partial and include transfer fees.
  class Refund < LoggableItem
    def initialize(date:, note: nil)
      @date = validate_date(date)
      @note = note
    end

    # This has to be done after #initialize.
    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end

  class Expense < LoggableItem
    self.private_attributes = [:total_usd, :total_eur]

    def initialize(date:, desc:, total:, tip: 0, location:, currency:, note: nil, tag: nil, payment_method:, total_usd: nil, total_eur: nil, **rest)
      unless rest.empty?
        raise ArgumentError.new("Unexpected key(s): #{rest.keys.inspect}")
      end

      @date     = validate_date(date)
      @desc     = validate_desc(desc)
      @total    = validate_amount_in_cents(total) # Including tip.
      @tip      = validate_amount_in_cents(tip)
      @currency = validate_currency(currency)
      @note     = note
      @tag      = validate_tag(tag) if tag && ! tag.empty?
      @location = location
      @payment_method = payment_method

      @total_usd = if total_usd then validate_amount_in_cents(total_usd)
      elsif @currency == 'USD' then @total
      else convert_currency(@total, @currency, 'USD') end

      @total_eur = if total_eur then validate_amount_in_cents(total_eur)
      elsif @currency == 'EUR' then @total
      else convert_currency(@total, @currency, 'EUR') end
    end

    # This has to be done after #initialize.
    self.attributes.each do |attribute|
      attr_accessor attribute
    end
  end
end
