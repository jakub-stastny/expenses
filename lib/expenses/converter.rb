require 'json'
require 'open-uri'
require 'socket' # So we can rescue from SocketError. Do we need it though since it doesn't come with open-uri?

=begin
This occured once, but I can't see why would that happen, keep an eye on it.

flashcards(master*) % expense +                                                                                                                                                              [0]
/Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/converter.rb:36:in `convert': undefined method `[]' for nil:NilClass (NoMethodError)
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/models/loggable_item.rb:90:in `convert_currency'
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/models/expense.rb:36:in `get_exhange_rate'
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/models/expense.rb:29:in `get_exhange_rates'
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/commands/add.rb:61:in `block in run'
       	from /Users/botanicus/Dropbox/Projects/Software/refined-refinements/lib/refined-refinements/curses/app.rb:40:in `block in run'
       	from /Users/botanicus/Dropbox/Projects/Software/refined-refinements/lib/refined-refinements/curses/app.rb:37:in `loop'
       	from /Users/botanicus/Dropbox/Projects/Software/refined-refinements/lib/refined-refinements/curses/app.rb:37:in `run'
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/commands/add.rb:34:in `run'
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/lib/expenses/commander.rb:31:in `run'
       	from /Users/botanicus/Dropbox/Projects/Software/expenses/bin/expense:10:in `<main>'
=end

module Expenses
  class ConversionError < StandardError; end

  class Converter
    # @api private
    def self.currency_rates
      @currency_rates ||= Hash.new do |hash, key|
        unless hash[key] = self.get_currency_rates_for(key)
          raise "Cannot get currency rates for #{key}."
        end
      end
    end

    # @api private
    def self.get_currency_rates_for(currency)
      open("http://api.fixer.io/latest?base=#{currency}") do |stream|
        return JSON.parse(stream.read)['rates']
      end
    end

    attr_reader :base_currency
    def initialize(base_currency)
      @base_currency = base_currency
    end

    def convert(dest_currency, amount)
      unless amount.is_a?(Numeric)
        raise TypeError.new("Amount for #{base_currency} -> #{dest_currency} conversion has to be a number, ideally integer, was #{amount.inspect}.")
      end

      return amount if @base_currency == dest_currency
      currency_rates[dest_currency] * amount
    rescue ::SocketError => error
      raise ConversionError.new(error)
    end

    private
    def currency_rates
      self.class.currency_rates[@base_currency]
    end
  end
end
