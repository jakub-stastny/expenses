# frozen_string_literal: true

require 'refined-refinements/colours'
require 'expenses/ui/screens/inspect_screen'
require 'expenses/ui/attributes/expense_screen_attributes'

module Expenses
  class ExpenseScreen < InspectScreen
    using RR::ColourExts

    def attributes
      ExpenseScreenAttributes::ALL
    end

    def initialize(expense)
      @expense = expense
    end

    def run(commander, commander_window, selected_attribute = nil, last_run_message = nil)
      attributes_with_guessed_defaults = [:date, :location, :payment_method] | $GUESSED_DEFAULTS
      empty_attributes = [:vale_la_pena, :note, :tip]

      self.attributes.each do |attribute|
        if (attributes_with_guessed_defaults | empty_attributes).include?(attribute.name)
          attribute.highlight!
        end
      end

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
          total = @expense.items.sum(&:total)
          if @expense.currency == 'EUR'
            commander_window.write("       <bold>Total:</bold> <red>#{Utils.format_cents_to_money(total)} #{@expense.currency}</red>\n")
          else
            total_eur = Converter.new(@expense.currency).convert('EUR', total)
            commander_window.write("       <bold>Total:</bold> <red>#{Utils.format_cents_to_money(total_eur)} #{@expense.currency}</red> (#{total_eur} EUR)\n")
          end
        end

        # commander_window.setpos(commander_window.cury + 5, 0) # TODO make work.
        commander_window.refresh
      end
    end
  end
end
