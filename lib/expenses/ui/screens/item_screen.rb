require 'expenses/ui/screens/inspect_screen'

module Expenses
  class ItemScreen < InspectScreen
    def help
      {
        quantity: "Press <red.bold>e</red.bold> to edit.",
        # unit_price: "Press <red.bold>e</red.bold> to edit.",
        unit: "Press <red.bold>e</red.bold> to edit.",
        desc: "Press <red.bold>e</red.bold> to edit.",
        total: "Press <red.bold>e</red.bold> to edit.",
        note: "Press <red.bold>n</red.bold> to edit.",
        tag: "Press <red.bold>#</red.bold> to set.",
        vale_la_pena: "Press <red.bold>v</red.bold>/<red.bold>V</red.bold> to cycle between values.",
        count: "Press <red.bold>c/C</red.bold> to increase/decrease count or press <red.bold>e</red.bold> to edit."
      }
    end


    def initialize(item)
      @item = item
    end

    def run(commander, commander_window)
      super(commander, commander_window, 'Item') do
        @item.data
      end
    end
  end
end
