module Expenses
  class InspectScreen
    def highlight(key, value)
      case value
      when Date
        [:magenta, value.strftime('%A %d/%m')]
      when nil
        [:cyan, 'nil']
      when true, false
        [:red, value.to_s]
      when Integer
        if [:total, :tip, :unit_price].include?(key)
          [:red, Utils.format_cents_to_money(value)]
        else
          [:red, value]
        end
      when String
        [:green, "\"#{value}\""]
      else
        raise value.inspect
      end
    end
  end
end
