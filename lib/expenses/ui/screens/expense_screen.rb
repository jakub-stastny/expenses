require 'refined-refinements/colours'
require 'expenses/ui/screens/inspect_screen'

module Expenses
  class ExpenseScreen < InspectScreen
    using RR::ColourExts

    def help
      {
        date: "Set to previous/next day by pressing <red.bold>d</red.bold>/<red.bold>D</red.bold>.",
        desc: nil,
        total: nil, # To tam ted neni.
        location: "Press <red.bold>l</red.bold>/<red.bold>L</red.bold> to cycle between values.",
        currency: "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values.",
        payment_method: "Press <red.bold>p</red.bold>/<red.bold>P</red.bold> to cycle between values.",
        tip: "Press <red.bold>t</red.bold> to edit.",
        note: "Press <red.bold>n</red.bold> to edit.",
        tag: "Press <red.bold>#</red.bold> to set.",
        vale_la_pena: "Press <red.bold>v</red.bold>/<red.bold>V</red.bold> to cycle between values."
      }
    end

    def hidden_attributes
      # We don't know the fee yet, that's what review is for.
      Expense.private_attributes + [:fee, :items]
    end

    def attributes_with_guessed_defaults
      $GUESSED_DEFAULTS ||= Array.new
      [:date, :location, :payment_method] | $GUESSED_DEFAULTS
    end

    def empty_attributes
      [:vale_la_pena, :note, :tip]
    end

    def initialize(expense)
      @expense = expense
    end

    def run(commander, commander_window, yposition)
      super(commander, commander_window, 'Expense', yposition) do
        @expense.public_data.merge(tag: @expense.tag)
      end

      self.display_items(commander, commander_window, yposition)
    end

    def display_items(commander, commander_window, yposition)
      unless @expense.items.empty?
        commander_window.write("  <yellow>items:</yellow> # Press <red.bold>i</red.bold> to add an item.\n")
        @expense.items.each do |item|
          str = item.quantity ? "<bold>#{item.quantity}#{item.unit}</bold> " : ''
          str += "x <bold>#{item.count}</bold>" if item.count
          commander_window.write("    -  <red>#{Utils.format_cents_to_money(item.total)}</red> #{[item.desc, str].join(' ')} <green>#{item.tag}</green>\n")
          commander_window.write("             #{item.note}\n") if item.note

          if item.vale_la_pena
            tag = case item.vale_la_pena
            when 0 then 'green'
            when 1 then 'red'
            when 2 then 'yellow' end
            commander_window.write("             <#{tag}>#{SerialisableItem::VALE_LA_PENA_LABELS[item.vale_la_pena]}</#{tag}>\n")
          end
        end

        if @expense.items.length >= 2
          commander_window.write("       <bold>Total:</bold> <red>#{Utils.format_cents_to_money(@expense.items.sum(&:total))}</red>\n")
        end

        commander_window.refresh
      end
    end
  end
end
