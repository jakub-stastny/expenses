require 'expenses/item'
require 'expenses/commands/lib/common_prompts'
require 'expenses/commands/commanders/item_screen'

module Expenses
  class ItemCommander
    include CommonPrompts

    def initialize(commander)
      @commander, @prompt = commander, RR::Prompt.new
    end

    def run
      prompt_desc
      prompt_total

      item = Item.new(@prompt.data)

      @commander.command('x') do |commander_window|
        item.quantity ||= 1
        item.quantity += 1
      end

      @commander.command('X') do |commander_window|
        item.quantity ||= 1
        if item.quantity == 1
          item.quantity = nil
        else
          item.quantity -= 1
        end
      end

      @commander.loop do |item_commander, item_commander_window|
        ItemScreen.new(item).run(item_commander_window)
      end
    end
  end
end
