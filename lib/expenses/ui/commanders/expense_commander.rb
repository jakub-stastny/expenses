require 'refined-refinements/colours'
require 'expenses/ui/commanders/commander_mode'
require 'expenses/ui/screens/item_screen'
require 'expenses/ui/screens/tags_screen'
require 'expenses/ui/screens/expense_screen'

module Expenses
  class ExpenseCommander < CommanderMode
    using RR::ColourExts

    def initialize(app)
      @app, @prompt = app, RR::Prompt.new do |prompt|
        app.readline(prompt)
      end
    end

    def run(collection, expense)
      commander = @app.commander
      expense_screen = ExpenseScreen.new(expense)

      super(@app, commander, collection, expense, expense_screen)

      commander.command('#') do |commander_window|
        TagCommander.new(@app).run(collection, expense)
      end

      commander.command('i') do |commander_window|
        ItemCommander.new(@app).run(collection, expense)
      end

      commander.command('s', 'save') do |commander_window|
        collection << expense
        collection.save
        raise QuitError.new # Quit the commander.
        app.destroy # Quit the app.

        puts "\nExpense #{collection.items.last.serialise.inspect} has been saved."
      end

      commander.command('q', 'quit without saving') do |commander_window|
        @app.destroy
      end

      commander.loop do |commander, commander_window|
        expense_screen.run(commander, commander_window, @selected_attribute, @last_run_message)
        @last_run_message = nil
      end
    end
  end
end
