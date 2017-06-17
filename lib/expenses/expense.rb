require 'date'
require 'expenses/converter'

module Expenses
  class Expense
    TYPES = ['indulgence', 'essential', 'travelling', 'long_term', 'gift']

    def self.deserialise(data)
      data = data.reduce(Hash.new) do |result, (key, value)|
        result.merge(key.to_sym => value)
      end

      # The following would happen anyway, we're only providing a better message.
      required_keys = self.instance_method(:initialize).parameters[0..-2].
        select { |type, name| type == :keyreq }.map(&:last)

      unless required_keys.all? { |required_key| data.has_key?(required_key) }
        missing_keys = required_keys - data.keys
        raise ArgumentError.new(
          "Expense #{data.inspect} has the following key(s) missing: #{missing_keys.inspect}")
      end

      self.new(data.tap { |data|
        data[:date] = Date.parse(data[:date])
      })
    end

    attr_accessor :date, :type, :desc, :total, :tip, :currency, :note, :tag, :location, :total_usd, :total_eur
    def initialize(date:, type:, desc:, total:, tip: 0, currency:, note: nil, tag: nil, location:, total_usd: nil, total_eur: nil, **rest)
      unless rest.empty?
        raise ArgumentError.new("Unexpected key(s): #{rest.keys.inspect}")
      end

      @date     = validate_date(date)
      @type     = validate_type(type)
      @desc     = validate_desc(desc)
      @total    = validate_amount_in_cents(total) # Including tip.
      @tip      = validate_amount_in_cents(tip)
      @currency = validate_currency(currency)
      @note     = note
      @tag      = validate_tag(tag) if tag && ! tag.empty?
      @location = location

      @total_usd = if total_usd then validate_amount_in_cents(total_usd)
      elsif @currency == 'USD' then @total
      else convert_currency(@total, @currency, 'USD') end

      @total_eur = if total_eur then validate_amount_in_cents(total_eur)
      elsif @currency == 'EUR' then @total
      else convert_currency(@total, @currency, 'EUR') end
    end

    def convert_currency(amount, base_currency, dest_currency)
      converter = Converter.new(base_currency)
      converter.convert(dest_currency, amount).round # It's already in cents.
    rescue ConversionError
      # Return nil if there is no connection.
    end

    def serialise
      keys = self.method(:initialize).parameters[0..-2].map(&:last)
      keys.reduce(Hash.new) do |result, key|
        value = self.send(key)
        unless [nil, 0, ''].include?(value)
          result.merge(key => value)
        else
          result
        end
      end
    end

    private
    def validate_date(date)
      unless date.is_a?(Date)
        raise TypeError.new("Date has to be an instance of Date.")
      end

      date
    end

    def validate_type(type)
      unless TYPES.include?(type)
        raise ArgumentError.new("Unknown type: #{type}.")
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

    def validate_tag(tag)
      unless tag.match(/^#[a-z_]+$/)
        raise ArgumentError.new("Tag has to be a #word_or_two.")
      end

      tag
    end
  end
end
