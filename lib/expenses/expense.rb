require 'date'
require 'open-uri'
require 'json'

module Expenses
  class Expense
    def self.currency_rates
      @currency_rates ||= Hash.new
    end

    def self.fixer_url(base_currency)
      "http://api.fixer.io/latest?base=#{base_currency}"
    end

    TYPES = {indulgence: 'I', essential: 'E', travelling: 'T', long_term: 'L'}

    attr_reader :date, :type, :desc, :total, :tip, :currency, :note, :total_usd, :total_eur
    def initialize(date, type_abbrev, desc, total, tip, currency, note = nil, total_usd = nil, total_eur = nil)
      @date     = validate_date(date)
      @type     = validate_type(type_abbrev)
      @desc     = validate_desc(desc)
      @total    = validate_amount_in_cents(total) # Including tip.
      @tip      = validate_amount_in_cents(tip)
      @currency = validate_currency(currency)
      @note     = note

      @total_usd = if total_usd then total_usd
      elsif @currency == 'USD' then @total
      else convert_currency(@total, @currency, 'USD') end

      @total_eur = if total_eur then total_eur
      elsif @currency == 'EUR' then @total
      else convert_currency(@total, @currency, 'EUR') end
    end

    def convert_currency(amount, base_currency, dest_currency)
      self.class.currency_rates[base_currency] ||= open(self.class.fixer_url(base_currency)) do |stream|
        self.class.currency_rates[base_currency] = JSON.parse(stream.read)['rates']
      end

      (self.class.currency_rates[base_currency][dest_currency] * amount).round # It's already in cents.
    end

    def serialise
      [@date.iso8601, TYPES[@type], @desc, @total, @tip, @currency, @note, @total_usd, @total_eur]
    end

    private
    def validate_date(date)
      unless date.is_a?(Date)
        raise TypeError.new("Date has to be an instance of Date.")
      end

      date
    end

    def validate_type(type_abbrev)
      unless type = TYPES.invert[type_abbrev]
        raise "Unknown type: #{type_abbrev}."
      end

      type
    end

    def validate_desc(desc)
      unless desc.is_a?(String)
        raise TypeError.new("Description has to be a string.")
      end

      desc
    end

    def validate_amount_in_cents(amount)
      unless amount.integer?
        raise TypeError.new("Amount has to be a round number.")
      end

      amount
    end

    def validate_currency(currency)
      unless currency.match(/^[A-Z]{3}$/)
        raise ArgumentError.new("Currency has to be a three-number code such as CZK.")
      end

      currency
    end
  end
end
