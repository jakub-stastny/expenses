require 'date'
require 'expenses/converter'
require 'expenses/serialisable_item'

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

    def data
      {type: type}.merge(super)
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

    protected
    def convert_currency(amount, base_currency, dest_currency)
      converter = Converter.new(base_currency)
      converter.convert(dest_currency, amount).round # It's already in cents.
    rescue ConversionError
      # Return nil if there is no connection.
    end
  end
end
