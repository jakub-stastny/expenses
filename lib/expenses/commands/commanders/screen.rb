require 'refined-refinements/colours'

module Expenses
  class InspectScreen
    using RR::ColourExts

    def help
      Hash.new
    end

    def hidden_attributes
      Array.new
    end

    def attributes_with_guessed_defaults
      Array.new
    end

    def empty_attributes
      Array.new
    end

    def run(commander, commander_window, label, &block)
      data = block.call

      items = data.reduce(Array.new) do |buffer, (key, value)|
        if self.hidden_attributes.include?(key)
          buffer
        else
          key_tag = self.attributes_with_guessed_defaults.include?(key) ? 'yellow.bold' : 'yellow'

          if key == :vale_la_pena && value
            value = Expense::VALE_LA_PENA_LABELS[value]
          end

          value_tag, value_text = highlight(key, value)
          buffer << ["<#{key_tag}>#{key}:</#{key_tag}> <#{value_tag}>#{value_text}</#{value_tag}>", self.help[key]]
        end
      end

      # longest_item = items.map(&:first).max_by(&:length)
      longest_item = items.map { |items| RR::TemplateString.new(items.first) }.max_by(&:length)

      if (@longest_item_length || 0) < longest_item.length
        @longest_item_length = longest_item.length + 7 # Give it some give, so it doesn't get updated too much.
      end

      expense_data = items.map do |(data, help)|
        data_length = RR::TemplateString.new(data).length
        spaces = ' ' * (@longest_item_length - data_length)
        "  #{data}#{spaces} # #{help}"
      end

      commander_window.write("<blue.bold>#{label}:</blue.bold>\n#{expense_data.join("\n")}\n")

      original_y = commander_window.cury
      commander_window.setpos(Curses.lines - 1, 0)
      commander_window.write(commander.help)
      commander_window.setpos(original_y, 0)
    end

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
      when Array
        [:yellow, value.inspect]
      else
        raise value.inspect
      end
    end
  end
end
