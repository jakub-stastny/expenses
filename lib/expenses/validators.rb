# frozen_string_literal: true

module Expenses
  module Validators
    def validate_date(date_or_date_string)
      if date_or_date_string.is_a?(Date)
        date_or_date_string
      elsif /^\d{4}-\d{2}-\d{2}$/.match?(date_or_date_string)
        Date.parse(date_or_date_string)
      else
        raise TypeError.new("Date has to be an instance of Date.")
      end
    end

    def validate_type(type)
      unless self.class.types.include?(type)
        raise ArgumentError.new("Unknown type: #{type}.")
      end

      type
    end

    def validate_desc(desc)
      raise TypeError.new("Description has to be a string.") unless desc.is_a?(String)

      desc
    end

    def validate_amount_in_cents(amount)
      raise TypeError.new("Amount has to be a round number.") unless amount.integer?

      amount
    end

    def validate_currency(currency)
      unless /^[A-Z]{3}$/.match?(currency)
        raise ArgumentError.new("Currency has to be a three-number code such as CZK.")
      end

      currency
    end

    def validate_tag(tag)
      unless /^#[a-z_\d]+$/.match?(tag)
        raise ArgumentError.new("Tag has to be a #word_or_two.")
      end

      tag
    end

    def validate_integer(integer)
      unless integer.respond_to?(:even?)
        raise ArgumentError.new("Expected integer, not #{integer.inspect}.")
      end

      integer
    end

    def validate_vale_la_pena(value)
      raise "vale_la_pena : #{value.inspect}" unless [nil, 0, 1, 2].include?(value)

      value
    end
  end
end
