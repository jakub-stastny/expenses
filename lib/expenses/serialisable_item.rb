require 'expenses/validators'

module Expenses
  class SerialisableItem
    include Validators

    VALE_LA_PENA_LABELS = ['yes', 'no', 'too expensive']

    def self.attributes
      @attributes ||= self.instance_method(:initialize).parameters.map(&:last)
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

    def data
      keys = self.method(:initialize).parameters.map(&:last)
      keys.reduce(Hash.new) do |result, key|
        result.merge(key => self.send(key))
      end
    end

    def serialise
      self.data.reduce({type: self.class.type_name}) do |result, (key, value)|
        unless [nil, 0, ''].include?(value) || (value.respond_to?(:empty?) && value.empty?)
          result.merge(key => value)
        else
          result
        end
      end
    end

    def ==(anotherExpense)
      self.serialise == anotherExpense.serialise
    end
  end
end
