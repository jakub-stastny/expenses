# frozen_string_literal: true

module Expenses
  module Validators
    def validate_date(date_or_date_string)
      if date_or_date_string.is_a?(Date)
        date_or_date_string
      elsif date_or_date_string =~ /^\d{4}-\d{2}-\d{2}$/
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
      unless currency =~ /^[A-Z]{3}$/
        raise ArgumentError.new("Currency has to be a three-number code such as CZK.")
      end

      currency
    end

    def validate_tag(tag)
      unless tag =~ /^#[a-z_\d]+$/
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
      unless [nil, 0, 1, 2].include?(value)
        raise "vale_la_pena : #{value.inspect}"
      end

      value
    end
  end
end
