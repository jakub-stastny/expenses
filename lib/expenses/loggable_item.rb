require 'date'
require 'expenses/converter'

module Expenses
  class LoggableItem
    def self.inherited(inherited_class)
      self.types[inherited_class.type_name] = inherited_class
    end

    def self.type_name
      self.name.split('::').last.gsub(/[A-Z]/) { |capital_letter| "_#{capital_letter.downcase}" }[1..-1].to_sym
    end

    def self.types
      @@types ||= Hash.new
    end

    def self.attributes
      @attributes ||= self.instance_method(:initialize).parameters.map(&:last)
    end

    def self.private_attributes
      @private_attributes ||= Array.new
    end

    def self.private_attributes=(list)
      @private_attributes = list
    end

    def self.public_attributes
      self.attributes - self.private_attributes
    end

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

      loggable_item_class = self.types[data[:type].to_sym] || raise("Unknown type #{data[:type]}.")
      data.delete(:type)
      loggable_item_class.new(data.tap { |data|
        data[:date] = Date.parse(data[:date])
      })
    end

    def type
      self.class.type_name
    end

    def data
      keys = self.method(:initialize).parameters.map(&:last)
      keys.reduce(Hash.new) do |result, key|
        result.merge(key => self.send(key))
      end
    end

    def public_data
      self.data.reduce(Hash.new) do |result, (key, value)|
        unless self.class.private_attributes.include?(key)
          result.merge(key => value)
        else
          result
        end
      end
    end

    def serialise
      self.data.reduce({type: self.class.type_name}) do |result, (key, value)|
        unless [nil, 0, ''].include?(value)
          result.merge(key => value)
        else
          result
        end
      end
    end

    def ==(anotherExpense)
      self.serialise == anotherExpense.serialise
    end

    protected
    def convert_currency(amount, base_currency, dest_currency)
      converter = Converter.new(base_currency)
      converter.convert(dest_currency, amount).round # It's already in cents.
    rescue ConversionError
      # Return nil if there is no connection.
    end

    def validate_date(date)
      unless date.is_a?(Date)
        raise TypeError.new("Date has to be an instance of Date.")
      end

      date
    end

    def validate_type(type)
      unless self.class.types.include?(type)
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
