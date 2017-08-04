module Expenses
  class ItemCommander
    def initialize(commander)
      @commander = commander
    end

    # First ask prompts, then instantiate and show editor, same as with expenses.
    def run
      # commander.command('x') do |commander_window|
      #   expense.quantity ||= 1
      #   expense.quantity += 1
      # end
      #
      # commander.command('X') do |commander_window|
      #   expense.quantity ||= 1
      #   if expense.quantity == 1
      #     expense.quantity = nil
      #   else
      #     expense.quantity -= 1
      #   end
      # end

      # quantity: "Press <red.bold>x/X</red.bold> to increase/decrease quantity or press <red.bold>e</red.bold> to edit.",
      # unit_price: "Press <red.bold>e</red.bold> to edit.",
      # unit: "Press <red.bold>e</red.bold> to edit."
      item_commander.loop do |item_commander, item_commander_window|
        puts "New item:"
      end
    end
  end
end
