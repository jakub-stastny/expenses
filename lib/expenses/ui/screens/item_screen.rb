# frozen_string_literal: true

require 'expenses/ui/screens/inspect_screen'
require 'expenses/ui/attributes/item_screen_attributes'

module Expenses
  class ItemScreen < InspectScreen
    def attributes
      ItemScreenAttributes::ALL
    end

    def initialize(item)
      @item = item
    end

    def run(commander, commander_window, selected_attribute = nil, last_run_message = nil)
      super(commander, commander_window, 'Item', selected_attribute, last_run_message) do
        @item.data
      end
    end
  end
end
