require 'refined-refinements/colours'
require 'expenses/ui/screens/inspect_screen'
require 'expenses/ui/screens/expense_screen_attributes'

module Expenses
  class ExpenseScreen < InspectScreen
    using RR::ColourExts

    def attributes
      ExpenseScreenAttributes::ALL
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

    def run(commander, commander_window, selected_attribute = nil, last_run_message = nil)
      super(commander, commander_window, 'Expense', selected_attribute, last_run_message) do
        @expense.public_data.merge(tag: @expense.tag)
      end

      self.display_items(commander, commander_window, selected_attribute)
    end

    def display_items(commander, commander_window, selected_attribute)
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
