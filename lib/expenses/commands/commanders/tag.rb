module Expenses
  class TagCommander
    def initialize(commander)
      @commander = commander
    end

    # TODO: cycle_between_values, cycle_backwards_between_values, cache_values_for
    #   and app.readline doesn't exist here.
    def run(expenses, expense)
      @commander.command(['h', 259], "select the previous tag") do |tag_commander_window|
        cycle_backwards_between_values(expenses, expense, :tag)
      end

      @commander.command(['#', 'j', 258], "select the next tag") do |tag_commander_window|
        cycle_between_values(expenses, expense, :tag)
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
          values = self.cache_values_for(expenses, :tag)
          new_tag = app.readline("<cyan.bold>#{values.length}</cyan.bold> #{beginning}")
          expense.tag = new_tag
        end
      end

      @commander.loop do |tag_commander, tag_commander_window|
        values = self.cache_values_for(expenses, :tag)

        values.each.with_index do |tag, index|
          if expense.tag == tag
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
