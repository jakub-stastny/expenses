require 'refined-refinements/colours'
require 'expenses/models/item'
require 'expenses/commands/lib/common_prompts'
require 'expenses/ui/screens/item_screen'
require 'expenses/ui/commanders/commander_mode'
require 'expenses/ui/commanders/tag_commander'

module Expenses
  class ItemCommander < CommanderMode
    include CommonPrompts

    def initialize(app)
      @app, @prompt = app, RR::Prompt.new do |prompt|
        app.readline(prompt)
      end
    end

    def run(collection, expense)
      window = Curses::Window.new(Curses.lines, Curses.cols, 0, 0)
      window.refresh

      prompt_desc
      prompt_total

      data = @prompt.data
      total_data = data.delete(:total)
      data.merge!(total_data)

      item = Item.new(@prompt.data)

      commander = @app.commander

      super(commander, @app, @prompt, item)

      commander.command('x') do |commander_window|
        item.quantity ||= 1
        item.quantity += 1
      end

      commander.command('X') do |commander_window|
        item.quantity ||= 1
        if item.quantity == 2
          item.quantity = nil
        else
          item.quantity -= 1
        end
      end

      commander.command('#') do |commander_window|
        TagCommander.new(@app).run(collection.expenses, expense)

        # case expense.tag
        # when '#fuel'
        #   expense.unit_price ||= prompt_money(:unit_price, 'Unit price')
        #   expense.quantity ||= prompt_money(:quantity, 'Litres')
        # end

        # @tag_editor_window.refresh; sleep 3 ####
      end

      # Copied from expense.rb
      commander.command('n') do |commander_window|
        @prompt = self.prompt_proc(@app, commander_window)

        commander_window.setpos(Curses.lines, 0)

        @prompt.prompt(:note, 'Note') do
          clean_value { |raw_value| raw_value }
        end

        item.note = @prompt.data[:note]
      end

      commander.command('s', 'save the item') do |commander_window|
        expense.items << item
        raise QuitError.new # Quit the commander.
        # TODO: Display it in the parent window somehow.
        # puts "\nExpense #{@collection.items.last.serialise.inspect} has been saved."
      end

      commander.command('q', 'quit adding the item') do |commander_window|
        raise QuitError.new
      end

      commander.loop do |commander, commander_window|
        ItemScreen.new(item).run(commander, commander_window)
      end
    end
  end
end
