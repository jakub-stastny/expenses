require 'refined-refinements/colours'
require 'expenses/commands/commanders/screen'

module Expenses
  class ExpenseScreen < InspectScreen
    using RR::ColourExts

    HELP ||= {
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
    HIDDEN_ATTRIBUTES ||= Expense.private_attributes + [:fee, :items]

    ATTRIBUTES_WITH_GUESSED_DEFAULTS ||= [:date, :location, :payment_method, :tag]
    EMPTY_ATTRIBUTES ||= [:vale_la_pena, :note, :tip]

    def initialize(expense)
      @expense = expense
    end

    def run(commander, commander_window)
      super(commander, commander_window, 'Expense') do
        @expense.public_data
      end
    end
  end
end
