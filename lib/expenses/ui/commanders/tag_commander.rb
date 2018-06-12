# frozen_string_literal: true

require 'refined-refinements/colours'
require 'expenses/query_engine'
require 'expenses/ui/commanders/commander_mode'

module Expenses
  class TagCommander < CommanderMode
    using RR::ColourExts

    def initialize(app)
      @commander = app.commander
    end

    def run(collection, item_or_expense)
      qe = QueryEngine.new(collection)

      @commander.command(['h', 259], "select the previous tag") do |tag_commander_window|
        _cycle_backwards_between_values(item_or_expense, :tag)
      end

      @commander.command(['#', 'j', 258], "select the next tag") do |tag_commander_window|
        _cycle_between_values(item_or_expense, :tag)
      end

      # 27 is Escape, 4 is Ctrl+d.
      @commander.command(['q', 27, 4], "quit") do |tag_commander_window|
        # TODO: clean the buffer.
        # raise QuitError.new
        exit # Don't report balance.
      end

      @commander.command([13], "set") do |tag_commander_window|
        # TODO: Use Enter to confirm the selection OR the @buffer, make the other ones like q not setting.
        # TODO: clean the buffer.
        raise QuitError.new
      end

      @commander.default_command do |tag_commander_window, char|
        if char.is_a?(String)
          beginning = "##{char}"
          values = self.cache_values_for(item_or_expenses, :tag)
          new_tag = app.readline("<cyan.bold>#{values.length}</cyan.bold> #{beginning}")
          item_or_expense.tag = new_tag
        end
      end

      @commander.loop do |tag_commander, tag_commander_window|
        values = self.cache[:"values_for_tag"] = qe.tags

        values.each.with_index do |tag, index|
          if item_or_expense.tag == tag
            tag_commander_window.write("<cyan><bold>#{index + 1}</bold> #{tag}</cyan>\n")
          else
            tag_commander_window.write("<bold>#{index + 1}</bold> #{tag}\n")
          end
        end

        tag_commander_window.setpos(Curses.lines - 1, 0)
        tag_commander_window.write(tag_commander.help)
        # tag_commander.destroy
      end
    end
  end
end
