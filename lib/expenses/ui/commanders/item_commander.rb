# frozen_string_literal: true

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
      data[:tag] = expense.tag || QueryEngine.new(collection).tags[0]

      item = Item.new(@prompt.data)

      commander = @app.commander
      item_screen = ItemScreen.new(item)

      super(@app, commander, collection, item, item_screen)

      commander.command('#') do |commander_window|
        TagCommander.new(@app).run(collection, item)

        # case expense.tag
        # when '#fuel'
        #   TODO: Ask additional details. Such as #alcohol, OK, how strong?
        #   Presuming we already know how much from the quantity.
        # end
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
        item_screen.run(commander, commander_window)
      end
    end
  end
end
