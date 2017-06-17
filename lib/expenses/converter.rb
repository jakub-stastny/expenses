require 'json'
require 'open-uri'

module Expenses
  class ConversionError < StandardError; end

  class Converter
    def self.currency_rates
      @currency_rates ||= Hash.new
    end

    attr_reader :base_currency
    def initialize(base_currency)
      @base_currency = base_currency
    end

    def convert(dest_currency, amount)
      self.class.currency_rates[@base_currency] ||= open(fixer_url(@base_currency)) do |stream|
        self.class.currency_rates[@base_currency] = JSON.parse(stream.read)['rates']
      end

      self.class.currency_rates[@base_currency][dest_currency] * amount
    rescue SocketError => error
      raise ConversionError.new(error)
    end

    private
    def fixer_url(base_currency)
      "http://api.fixer.io/latest?base=#{base_currency}"
    end
  end
end
