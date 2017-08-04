require 'refined-refinements/curses/app'
require 'refined-refinements/cli/prompt'
require 'expenses/commands/lib/common_prompts'
require 'expenses/commands/commanders/item'
require 'expenses/commands/commanders/tag'
require 'expenses/utils'

module Expenses
  module Commands
    class AddCommand < RR::Command
      using RR::ColourExts
      include CommonPrompts

      self.help = <<-EOF
        #{self.main_command} <red>+</red> <bright_black># Log a new expense.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args, @cache = collection, args, Hash.new
      end

      def run
        begin
          expenses = @collection.expenses
        rescue Errno::ENOENT
          expenses = Array.new
        end

        App.new.run do |app, window|
          @prompt = RR::Prompt.new do |prompt|
            app.readline(prompt)
          end

          # Required arguments that don't have reasonable defaults,
          # we ask for explicitly.
          prompt_desc
          prompt_total

          most_common_tag = Utils.most_common_attribute_value(expenses, :tag)

          # Here we could guess that if the total is over n, we'd default
          # to the last card payment method, but the problem is that since
          # we don't know the currency yet, we cannot make an assumption
          # whether the purchase was expensive or not.
          most_common_payment_method = Utils.most_common_attribute_value(expenses, :payment_method)

          total_data = @prompt.data.delete(:total)
          data_input = @prompt.data.merge(total: total_data[:total])

          data = data_input.merge(
            date: Date.today,
            currency: expenses.last ? expenses.last.currency : 'EUR',
            location: expenses.last ? expenses.last.location : 'online',
            tag: most_common_tag || '#groceries',
            payment_method: most_common_payment_method || 'cash')

          data.merge!(total_data)
          expense = Expense.new(**data)

          # Optional arguments or arguments with reasonable defaults.
          # Can be changed from the commander.
          commander = app.commander

          commander.command('d') do |commander_window|
            expense.date -= 1
          end

          commander.command('D') do |commander_window|
            unless expense.date == Date.today
              expense.date += 1
            end
          end

          commander.command('#') do |commander_window|
            TagCommander.new(app.commander).run(expense)

            # case expense.tag
            # when '#fuel'
            #   expense.unit_price ||= prompt_money(:unit_price, 'Unit price')
            #   expense.quantity ||= prompt_money(:quantity, 'Litres')
            # end

            # @tag_editor_window.refresh; sleep 3 ####
          end

          {
            currency: 'c', payment_method: 'p'
          }.each do |attribute, command|
            commander.command(command) do |commander_window|
              cycle_between_values(expenses, expense, attribute)
            end

            commander.command(command.upcase) do |commander_window|
              cycle_backwards_between_values(expenses, expense, attribute)
            end
          end

          commander.command('v') do |commander_window|
            values = Expense::VALE_LA_PENA_LABELS.length.times.map { |i| i } + [nil]
            @cache[:"values_for_#{:vale_la_pena}"] = values # TODO: Worth sorting by how common they are.
            _cycle_between_values(expense, :vale_la_pena)
          end

          commander.command('V') do |commander_window|
            values = Expense::VALE_LA_PENA_LABELS.length.times.map { |i| i } + [nil]
            @cache[:"values_for_#{:vale_la_pena}"] = values # TODO: Worth sorting by how common they are.
            _cycle_backwards_between_values(expense, :vale_la_pena)
          end

          commander.command('l') do |commander_window|
            cycle_between_values(expenses, expense, :location)
            set_currency_based_on_location(expenses, expense)
            update_payment_method_if_online(expenses, expense)
          end

          commander.command('L') do |commander_window|
            cycle_backwards_between_values(expenses, expense, :location)
            set_currency_based_on_location(expenses, expense)
            update_payment_method_if_online(expenses, expense)
          end

          commander.command('g') do |commander_window|
            @prompt = self.prompt_proc(app, commander_window)

            y = commander_window.cury + ((Curses.lines - commander_window.cury) / 2) # TODO: This works, except the current position is (I think) wrong.
            commander_window.setpos(y, 0)
            prompt_money(:tip, 'Tip', allow_empty: true)
            expense.tip = @prompt.data[:tip]
          end

          commander.command('n') do |commander_window|
            @prompt = self.prompt_proc(app, commander_window)

            commander_window.setpos(Curses.lines, 0)

            @prompt.prompt(:note, 'Note') do
              clean_value { |raw_value| raw_value }
            end

            expense.note = @prompt.data[:note]
          end

          commander.command('i') do |commander_window|
            ItemCommander.new(app.commander).run
          end

          commander.command('e') do |commander_window|
            @prompt = self.prompt_proc(app, commander_window)

            editable_attributes = {
              desc:           -> { prompt_desc },
              total:          -> { prompt_total },
              location:       -> { @prompt.prompt(:location, 'Location') { clean_value { |raw_value| raw_value.strip } } },
              currency:       -> { @prompt.prompt(:currency, 'Currency') { clean_value { |raw_value| raw_value.strip } } }, # TODO: match /^[A-Z]{3}$/.
              payment_method: -> { @prompt.prompt(:payment_method, 'Payment method') { clean_value { |raw_value| raw_value.strip } } } # TODO: Ask for how much is there -> set expense.balance.
            }

            commander_window.setpos(Curses.lines - 3, 0)
            input = app.readline("<bold>Which attribute?</bold> ", commander_window)
            if editable_attributes.keys.include?(key = input.to_sym)
              attribute = input.to_sym
              new_value = editable_attributes[key].call
              expense.send("#{attribute}=", new_value)
            else
              # log ...
            end
          end

          commander.command('s', 'save') do |commander_window|
            @collection << expense
            @collection.save
            raise QuitError.new # Quit the commander.
            app.destroy # Quit the app.

            puts "\nExpense #{@collection.items.last.serialise.inspect} has been saved."
          end

          commander.command('q', 'quit without saving') do |commander_window|
            app.destroy
          end

          help = {
            date: "Set to previous/next day by pressing <red.bold>d</red.bold>/<red.bold>D</red.bold>.",
            desc: "Press <red.bold>e</red.bold> to edit.",
            total: "Press <red.bold>e</red.bold> to edit.",
            location: "Press <red.bold>l</red.bold>/<red.bold>L</red.bold> to cycle between values or add a new one by pressing <red.bold>e</red.bold>.",
            currency: "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values or set a new one by pressing <red.bold>e</red.bold>.",
            payment_method: "Press <red.bold>p</red.bold>/<red.bold>P</red.bold> to cycle between values or add a new one by pressing <red.bold>e</red.bold>.",
            tip: "Press <red.bold>g</red.bold> to edit.",
            note: "Press <red.bold>n</red.bold> to edit.",
            tag: "Press <red.bold>#</red.bold> to set.",
            vale_la_pena: "Press <red.bold>v</red.bold>/<red.bold>V</red.bold> to cycle between values."
          }

          hidden_attributes = Expense.private_attributes + [:fee, :items] # We don't know the fee yet, that's what review is for.

          attributes_with_guessed_defaults = [:date, :location, :payment_method, :tag]
          empty_attributes = [:vale_la_pena, :note, :tip]

          commander.loop do |commander, commander_window|
            items = expense.public_data.reduce(Array.new) do |buffer, (key, value)|
              if hidden_attributes.include?(key)
                buffer
              else
                key_tag = attributes_with_guessed_defaults.include?(key) ? 'yellow.bold' : 'yellow'

                if key == :vale_la_pena && value
                  value = Expense::VALE_LA_PENA_LABELS[value]
                end

                value_tag, value_text = highlight(key, value)
                buffer << ["<#{key_tag}>#{key}:</#{key_tag}> <#{value_tag}>#{value_text}</#{value_tag}>", help[key]]
              end
            end

            # longest_item = items.map(&:first).max_by(&:length)
            longest_item = items.map(&:first).max_by { |item| item.gsub(/<[^>]+>/, '').length }
            current_longest_item_length = longest_item.gsub(/<[^>]+>/, '').length

            if (@longest_item_length || 0) < current_longest_item_length
              @longest_item_length = current_longest_item_length + 7 # Give it some give, so it doesn't get updated too much.
            end

            expense_data = items.map do |(data, help)|
              data_length = data.gsub(/<[^>]+>/, '').length
              spaces = ' ' * (@longest_item_length - data_length)
              "  #{data}#{spaces} # #{help}"
            end

            commander_window.write("<blue.bold>Expense:</blue.bold>\n#{expense_data.join("\n")}\n")

            original_y = commander_window.cury
            commander_window.setpos(Curses.lines - 1, 0)
            commander_window.write(commander.help)
            commander_window.setpos(original_y, 0)
          end

          app.destroy
        end

        report_end_balance(expenses)

      rescue Interrupt
        puts; exit
      end

      def prompt_desc
        @prompt.prompt(:desc, 'Description') do
          clean_value { |raw_value| raw_value }

          validate_clean_value do |clean_value|
            clean_value && ! clean_value.empty?
          end
        end
      end


      # def prompt_tag(expenses)
      #   tags = expenses.map(&:tag).uniq.compact.sort # TODO: Sort by number of occurences.
      #   comp = Proc.new { |s| tags.grep(/^#{Regexp.escape(s)}/) }
      #
      #   @prompt.set_completion_proc(comp) do
      #     @prompt.prompt(:tag, 'Tag', help: 'use tab completion') do
      #       clean_value do |raw_value|
      #         raw_value.strip
      #       end
      #
      #       validate_clean_value do |clean_value|
      #         clean_value.match(/^#[a-z_]+$/)
      #       end
      #     end
      #   end
      # end

      def cache_values_for(expenses, attribute) # TODO: clear when new one is added (i. e. using the e command).
        @cache[:"values_for_#{attribute}"] ||= begin
          expenses.map(&attribute).uniq.sort_by { |value|
            expenses.count { |expense| expense.send(attribute) == value }
          }.reverse
        end
      end

      def init_last_index_cache(attribute, value)
        @cache[:"last_#{attribute}_index"] ||= begin
          cached_values = @cache[:"values_for_#{attribute}"]
          value == cached_values.first ? 0 : -1
        end
      end

      def reset_last_index_cache_if_last(attribute)
        if @cache[:"last_#{attribute}_index"] == @cache[:"values_for_#{attribute}"].length
          @cache[:"last_#{attribute}_index"] = 0
        end
      end

      def select_next_if_current_selection_equals_next_item(attribute, current_item)
        current_index = @cache[:"values_for_#{attribute}"].index(current_item)
        if current_index == @cache[:"last_#{attribute}_index"]
          @cache[:"last_#{attribute}_index"] += 1
        end
      end

      def blink_if_starting_over(attribute)
        if @cache[:"last_#{attribute}_index"] == 0
          # TODO: Blink when starting the next circle.
        end
      end

      def set_expense_attribute_to_selection(expense, attribute)
        values = @cache[:"values_for_#{attribute}"]
        expense.send(:"#{attribute}=", values[@cache[:"last_#{attribute}_index"]])
      end

      def cycle_between_values(expenses, expense, attribute)
        self.cache_values_for(expenses, attribute)
        _cycle_between_values(expense, attribute)
      end

      def _cycle_between_values(expense, attribute)
        self.init_last_index_cache(attribute, expense.send(attribute))
        @cache[:"last_#{attribute}_index"] += 1

        self.reset_last_index_cache_if_last(attribute)
        self.select_next_if_current_selection_equals_next_item(attribute, expense.send(attribute))

        self.blink_if_starting_over(attribute)
        self.set_expense_attribute_to_selection(expense, attribute)
      end

      def cycle_backwards_between_values(expenses, expense, attribute)
        self.cache_values_for(expenses, attribute)
        _cycle_backwards_between_values(expense, attribute)
      end

      def _cycle_backwards_between_values(expense, attribute)
        self.init_last_index_cache(attribute, expense.send(attribute))
        @cache[:"last_#{attribute}_index"] -= 1

        if @cache[:"last_#{attribute}_index"] < 0
          @cache[:"last_#{attribute}_index"] = @cache[:"values_for_#{attribute}"].length + @cache[:"last_#{attribute}_index"]
        end

        self.select_next_if_current_selection_equals_next_item(attribute, expense.send(attribute))

        self.blink_if_starting_over(attribute)
        self.set_expense_attribute_to_selection(expense, attribute)
      end

      def prompt_proc(app, commander_window)
        return RR::Prompt.new do |prompt|
          app.readline(prompt, commander_window) do |key| # TODO: Just quit the commander.
            raise QuitError.new if key.key_code == 27 # Escape.
          end
        end
      end

      def set_currency_based_on_location(expenses, expense)
        location = expense.location

        last_same_location_expense = expenses.reverse.find do |expense|
          expense.location == location
        end

        if last_same_location_expense
          expense.currency = last_same_location_expense.currency
        end
      end

      def update_payment_method_if_online(expenses, expense)
        most_common_online_payment_method = Utils.most_common_attribute_value(expenses.select { |expense| expense.location == 'online' }, :payment_method)
        expense.payment_method = most_common_online_payment_method if most_common_online_payment_method
      end

      def report_end_balance(expenses)
        expense = expenses.last
        balance = Utils.balance_for(@collection, expense.payment_method, expense.currency)

        payment_method_label = expense.payment_method == 'cash' ? expense.currency : expense.payment_method

        if balance
          puts "<green.bold>~</green.bold> Running total for <cyan.bold>#{payment_method_label}</cyan.bold> is <yellow.bold>#{Utils.format_cents_to_money(balance)}</yellow.bold>.".colourise
        else
          puts "<yellow>~</yellow> Unknown running total for <red>#{payment_method_label}</red>.".colourise
        end
      end

      def highlight(key, value)
        case value
        when Date
          [:magenta, value.strftime('%A %d/%m')]
        when nil
          [:cyan, 'nil']
        when true, false
          [:red, value.to_s]
        when Integer
          if [:total, :tip, :unit_price].include?(key)
            [:red, Utils.format_cents_to_money(value)]
          else
            [:red, value]
          end
        when String
          [:green, "\"#{value}\""]
        else
          raise value.inspect
        end
      end
    end
  end
end
