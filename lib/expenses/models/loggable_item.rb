# frozen_string_literal: true

require 'date'
require 'expenses/converter'
require 'expenses/models/serialisable_item'

module Expenses
  class LoggableItem < SerialisableItem
    include Validators

    def self.inherited(inherited_class)
      self.types[inherited_class.type_name] = inherited_class

      unless self.private_attributes.empty?
        inherited_class.private_attributes = self.private_attributes.dup
      end
    end

    def self.type_name
      self.name.split('::').last.gsub(/[A-Z]/) do |capital_letter|
        "_#{capital_letter.downcase}"
      end[1..-1].to_sym
    end

    def self.types
      @@types ||= Hash.new
    end

    def self.private_attributes
      @private_attributes ||= [:type]
    end

    def self.private_attributes=(list)
      @private_attributes = (list | [:type])
    end

    def self.public_attributes
      self.attributes - self.private_attributes
    end

    def type
      self.class.type_name
    end

    def self.deserialise(data)
      data = data.reduce(Hash.new) do |result, (key, value)|
        result.merge(key.to_sym => value)
      end

      data[:items]&.map! do |item_data| # TODO: Move into expense.
          Item.deserialise(item_data.reduce(Hash.new) { |result, (key, value)|
            result.merge(key.to_sym => value)
          })
      end

      # The following would happen anyway, we're only providing a better message.
      required_keys = self.instance_method(:initialize).parameters[0..-2].
        select { |type, name| type == :keyreq }.map(&:last)

      unless required_keys.all? { |required_key| data.key?(required_key) }
        missing_keys = required_keys - data.keys
        raise ArgumentError, "Expense #{data.inspect} has the following key(s) missing: #{missing_keys.inspect}"
      end

      loggable_item_class = self.types[data[:type].to_sym] || raise("Unknown type #{data[:type]}.")
      data.delete(:type)
      loggable_item_class.new(data.tap { |data|
        data[:date] = Date.parse(data[:date])
      })
    end

    def data
      {type: type}.merge(super)
    end

    def public_data
      self.data.reduce(Hash.new) do |result, (key, value)|
        if self.class.private_attributes.include?(key)
          result
        else
          result.merge(key => value)
        end
      end
    end

    protected
    def convert_currency(amount, base_currency, dest_currency)
      converter = Converter.new(base_currency)
      converter.convert(dest_currency, amount) # It's already in cents.
    rescue ConversionError
      # Return nil if there is no connection.
    end
  end
end
