require 'expenses/commands/commanders/screen'

module Expenses
  class ExpenseScreen < InspectScreen
    HELP = {
      date: "Set to previous/next day by pressing <red.bold>d</red.bold>/<red.bold>D</red.bold>.",
      desc: "Press <red.bold>e</red.bold> to edit.",
      total: "Press <red.bold>e</red.bold> to edit.",
      location: "Press <red.bold>l</red.bold>/<red.bold>L</red.bold> to cycle between values or add a new one by pressing <red.bold>e</red.bold>.",
      currency: "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values or set a new one by pressing <red.bold>e</red.bold>.",
      payment_method: "Press <red.bold>p</red.bold>/<red.bold>P</red.bold> to cycle between values or add a new one by pressing <red.bold>e</red.bold>.",
      tip: "Press <red.bold>g</red.bold> to edit.",
      note: "Press <red.bold>n</red.bold> to edit.",
      tag: "Press <red.bold>#</red.bold> to set.",
      vale_la_pena: "Press <red.bold>v</red.bold>/<red.bold>V</red.bold> to cycle between values."
    }

    # We don't know the fee yet, that's what review is for.
    HIDDEN_ATTRIBUTES = Expense.private_attributes + [:fee, :items]

    ATTRIBUTES_WITH_GUESSED_DEFAULTS = [:date, :location, :payment_method, :tag]
    EMPTY_ATTRIBUTES = [:vale_la_pena, :note, :tip]

    def initialize(expense)
      @expense = expense
    end

    def run(commander_window)
      items = @expense.public_data.reduce(Array.new) do |buffer, (key, value)|
        if HIDDEN_ATTRIBUTES.include?(key)
          buffer
        else
          key_tag = ATTRIBUTES_WITH_GUESSED_DEFAULTS.include?(key) ? 'yellow.bold' : 'yellow'

          if key == :vale_la_pena && value
            value = Expense::VALE_LA_PENA_LABELS[value]
          end

          value_tag, value_text = highlight(key, value)
          buffer << ["<#{key_tag}>#{key}:</#{key_tag}> <#{value_tag}>#{value_text}</#{value_tag}>", help[key]]
        end
      end

      # longest_item = items.map(&:first).max_by(&:length)
      longest_item = items.map(&:first).max_by { |item| item.gsub(/<[^>]+>/, '').length }
      current_longest_item_length = longest_item.gsub(/<[^>]+>/, '').length

      if (@longest_item_length || 0) < current_longest_item_length
        @longest_item_length = current_longest_item_length + 7 # Give it some give, so it doesn't get updated too much.
      end

      expense_data = items.map do |(data, help)|
        data_length = data.gsub(/<[^>]+>/, '').length
        spaces = ' ' * (@longest_item_length - data_length)
        "  #{data}#{spaces} # #{help}"
      end

      commander_window.write("<blue.bold>Expense:</blue.bold>\n#{expense_data.join("\n")}\n")

      original_y = commander_window.cury
      commander_window.setpos(Curses.lines - 1, 0)
      commander_window.write(commander.help)
      commander_window.setpos(original_y, 0)
    end
  end
end
