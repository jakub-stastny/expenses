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

      super(commander, @app, @prompt, expense)

      commander.command('d') do |commander_window|
        expense.date -= 1
      end

      commander.command('D') do |commander_window|
        unless expense.date == Date.today
          expense.date += 1
        end
      end

      commander.command('#') do |commander_window|
        TagCommander.new(@app).run(collection, expense)
      end

      {
        currency: 'c', payment_method: 'p'
      }.each do |attribute, command|
        commander.command(command) do |commander_window|
          cycle_between_values(collection.expenses, expense, attribute)
        end

        commander.command(command.upcase) do |commander_window|
          cycle_backwards_between_values(collection.expenses, expense, attribute)
        end
      end

      commander.command('v') do |commander_window|
        values = SerialisableItem::VALE_LA_PENA_LABELS.length.times.map { |i| i } + [nil]
        self.cache[:"values_for_#{:vale_la_pena}"] = values # TODO: Worth sorting by how common they are.
        _cycle_between_values(expense, :vale_la_pena)
      end

      commander.command('V') do |commander_window|
        values = SerialisableItem::VALE_LA_PENA_LABELS.length.times.map { |i| i } + [nil]
        self.cache[:"values_for_#{:vale_la_pena}"] = values # TODO: Worth sorting by how common they are.
        _cycle_backwards_between_values(expense, :vale_la_pena)
      end

      commander.command('l') do |commander_window|
        cycle_between_values(collection.expenses, expense, :location)
        set_currency_based_on_location(collection.expenses, expense)
        update_payment_method_if_online(collection.expenses, expense)
      end

      commander.command('L') do |commander_window|
        cycle_backwards_between_values(collection.expenses, expense, :location)
        set_currency_based_on_location(collection.expenses, expense)
        update_payment_method_if_online(collection.expenses, expense)
      end

      commander.command('g') do |commander_window|
        @prompt = self.prompt_proc(@app, commander_window)

        y = commander_window.cury + ((Curses.lines - commander_window.cury) / 2) # TODO: This works, except the current position is (I think) wrong.
        commander_window.setpos(y, 0)
        prompt_money(:tip, 'Tip', allow_empty: true)
        expense.tip = @prompt.data[:tip]
      end

      commander.command('n') do |commander_window|
        @prompt = self.prompt_proc(@app, commander_window)

        commander_window.setpos(Curses.lines, 0)

        @prompt.prompt(:note, 'Note') do
          clean_value { |raw_value| raw_value }
        end

        expense.note = @prompt.data[:note]
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
        ExpenseScreen.new(expense).run(commander, commander_window)
        unless expense.items.empty?
          commander_window.write("  <yellow>items:</yellow> # Press <red.bold>i</red.bold> to add an item.\n")
          expense.items.each do |item|
            str = item.quantity ? "<bold>#{item.quantity}#{item.unit}</bold> " : ''
            str += "x <bold>#{item.count}</bold>" if item.count
            commander_window.write("    -  <red>#{Utils.format_cents_to_money(item.total)}</red> #{[item.desc, str].join(' ')} <green>#{item.tag}</green>\n")
            commander_window.write("             #{item.note}\n") if item.note

            if item.vale_la_pena
              tag = case item.vale_la_pena
              when 0 then 'green'
              when 1 then 'red'
              when 2 then 'yellow' end
              commander_window.write("             <#{tag}>#{SerialisableItem::VALE_LA_PENA_LABELS[item.vale_la_pena]}</#{tag}>\n")
            end
          end

          if expense.items.length >= 2
            commander_window.write("       <bold>Total:</bold> <red>#{Utils.format_cents_to_money(expense.items.sum(&:total))}</red>\n")
          end

          commander_window.refresh
        end
      end
    end
  end
end
