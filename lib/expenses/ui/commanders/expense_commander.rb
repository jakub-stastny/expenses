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

      super(commander, @app, expense, expense_screen)

      expense_screen.attributes.each do |attribute|
        if attribute.globally_cyclable?
          command = attribute.global_cyclable_command
          commander.command([command, command.upcase]) do |char, commander_window|
            attribute.cycle(expense, char)
          end
        elsif attribute.globally_editable?
          command = attribute.global_editable_command
          commander.command([command, command.upcase]) do |char, commander_window|
            attribute.edit(expense, char)
          end
        end
      end

      commander.command('#') do |commander_window|
        TagCommander.new(@app).run(collection, expense)
      end

      commander.command(['j', 258]) do |commander_window|
        @selected_attribute = expense_screen.set_next_attribute
        # if expense_screen.editable_lines.include?(@yposition + 1)
        #   @yposition += 1
        # end
      end

      commander.command(['k', 259]) do |commander_window|
        @selected_attribute = expense_screen.set_previous_attribute
        # if expense_screen.editable_lines.include?(@yposition - 1)
        #   @yposition -= 1
        # end
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
