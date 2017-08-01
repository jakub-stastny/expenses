require 'refined-refinements/curses/app'
require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class AddCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>add</red> [word] [translations]
      EOF

      def initialize(manager, args)
        @manager, @args, @cache = manager, args, Hash.new
      end

      def run
        begin
          expenses = @manager.parse
        rescue Errno::ENOENT
          expenses = Array.new
        end

        # puts "Hello <dark>world</dark>!".colourise
        # puts "Hello <underline>world</underline>!".colourise
        # puts "Hello <negative>world</negative>!".colourise
        # puts "Hello <red.on_yellow>world</red.on_yellow>!".colourise
        # puts "<intense_cyan>Hello</intense_cyan> <on_intense_cyan>world</on_intense_cyan>!".colourise
        # puts "<bright_cyan>Hello</bright_cyan> <on_bright_cyan>world</on_bright_cyan>!".colourise

        App.new.run do |app, window|
          @prompt = RR::Prompt.new do |prompt|
            app.readline(prompt)
          end

          # Required arguments that don't have reasonable defaults,
          # we ask for explicitly.
          prompt_desc
          prompt_money(:total, 'Total')

          most_common_type = self.most_common_attribute_value(expenses, :type)
          most_common_tag  = self.most_common_attribute_value(expenses, :tag)

          # Here we could guess that if the total is over n, we'd default
          # to the last card payment method, but the problem is that since
          # we don't know the currency yet, we cannot make an assumption
          # whether the purchase was expensive or not.
          most_common_payment_method = self.most_common_attribute_value(expenses, :payment_method)

          data = @prompt.data.merge(
            type: most_common_type,
            date: Date.today,
            currency: expenses.last ? expenses.last.currency : 'EUR',
            location: expenses.last ? expenses.last.location : 'online',
            tag: most_common_tag || '#groceries',
            payment_method: most_common_payment_method || 'cash')
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
            tag_commander = app.commander

            tag_commander.command(['h', 259], "select the previous tag") do |tag_commander_window|
              cycle_backwards_between_values(expenses, expense, :tag)
            end

            tag_commander.command(['#', 'j', 258], "select the next tag") do |tag_commander_window|
              cycle_between_values(expenses, expense, :tag)
            end

            # 27 is Escape, 4 is Ctrl+d.
            tag_commander.command(['q', 27, 4], "quit") do |tag_commander_window|
              # TODO: clean the buffer.
              raise QuitError.new
            end

            tag_commander.command([13], "set") do |tag_commander_window|
              # TODO: Use Enter to confirm the selection OR the @buffer, make the other ones like q not setting.
              # TODO: clean the buffer.
              raise QuitError.new
            end

            tag_commander.default_command do |tag_commander_window, char|
              if char.is_a?(String)
                beginning = "##{char}"
                values = self.cache_values_for(expenses, :tag)
                new_tag = app.readline("<cyan.bold>#{values.length}</cyan.bold> #{beginning}")
                expense.tag = new_tag
              end
            end

            tag_commander.loop do |tag_commander, tag_commander_window|
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

            # indulgence: #eating_out, #crawings, #tea, #drinks
            # essential: #groceries (although ...), #mhd
            # travelling: #fuel, #vignette
            # maintenance: #car
            # ?: #social
            case expense.tag
            when '#fuel'
              unit_price = prompt_money(:unit_price, 'Unit price')
              litres = prompt_money(:liters, 'Liters')
              expense.extra_data = {unit_price: unit_price, litres: litres}
            end



            # @tag_editor_window.refresh; sleep 3 ####

            # OR ...
            # Press #, then display all of them with their indices and use:
            # 1. Pressing # again to cycle through.
            # 1. tab to complete
            # 2. and index to get the tag
            # 3. write a new value
          end

          {
            type: 't', currency: 'c', payment_method: 'p'
          }.each do |attribute, command|
            commander.command(command) do |commander_window|
              cycle_between_values(expenses, expense, attribute)
            end

            commander.command(command.upcase) do |commander_window|
              cycle_backwards_between_values(expenses, expense, attribute)
            end
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
            prompt_money(:tip, 'Tip')
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

          # TODO: Press 'e', then prompt "Which attribute? ", you say "ta<tab>",
          # it completes it to "tag", press Enter, then write the new value.
          # This is useful only for values that can have unlimited variations of
          # values such as tag, tip, total or if it's a new location, then location
          # as well, otherwise it's more convenient to cycle between the values
          # by pressing say "c" multiple times (first run: EUR, second: CZK ...).
          commander.command('e') do |commander_window|
            @prompt = self.prompt_proc(app, commander_window)

            # TODO: Use prompt here.
            editable_attributes = {
              desc:           -> { prompt_desc },
              total:          -> { prompt_money(:total, 'Total') },
              location:       -> { @prompt.prompt(:location, 'Location') { clean_value { |raw_value| raw_value.strip } } },
              currency:       -> { @prompt.prompt(:currency, 'Currency') { clean_value { |raw_value| raw_value.strip } } }, # TODO: match /^[A-Z]{3}$/.
              payment_method: -> { @prompt.prompt(:payment_method, 'Payment method') { clean_value { |raw_value| raw_value.strip } } }, # TODO: Ask for how much is there -> set expense.running_total.
              tag:            -> { @prompt.prompt(:tag, 'Tag') { clean_value { |raw_value| raw_value.strip } } } # TODO: match /^#/ and no spaces.
            }

            commander_window.setpos(Curses.lines - 3, 0)
            input = app.readline("<bold>Which attribute?</bold> ", commander_window)
            if editable_attributes.keys.include?(input.to_sym)
              attribute = input.to_sym
              new_value = app.readline("New value: ", commander_window)
              expense.send("#{attribute}=", new_value)
            else
              # log ...
            end
          end

          commander.command('s', 'save') do |commander_window|
            expenses << expense
            @manager.save(expenses)
            raise QuitError.new # Quit the commander.
            app.destroy # Quit the app.

            puts "\nExpense #{expenses.last.serialise.inspect} has been saved."
          end

          commander.command('q', 'quit without saving') do |commander_window|
            app.destroy
          end

          help = {
            date: "Set to previous/next day by pressing <red.bold>d</red.bold>/<red.bold>D</red.bold>.",
            type: "Press <red.bold>t</red.bold>/<red.bold>T</red.bold> to cycle between values.",
            desc: "Press <red.bold>e</red.bold> to edit.",
            total: "Press <red.bold>e</red.bold> to edit.",
            location: "Press <red.bold>l</red.bold>/<red.bold>L</red.bold> to cycle between values or add a new one by pressing <red.bold>e</red.bold>.",
            currency: "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values or set a new one by pressing <red.bold>e</red.bold>.",
            payment_method: "Press <red.bold>p</red.bold>/<red.bold>P</red.bold> to cycle between values or add a new one by pressing <red.bold>e</red.bold>.",
            tip: "Press <red.bold>g</red.bold> to edit.",
            note: "Press <red.bold>n</red.bold> to edit.",
            tag: "Press <red.bold>#</red.bold> to set."
          }

          attributes_with_guessed_defaults = [:date, :type, :location, :payment_method, :tag]

          commander.loop do |commander, commander_window|
            items = expense.public_data.reduce(Array.new) do |buffer, (key, value)|
              if Expense::PRIVATE_ATTRIBUTES.include?(key)
                buffer
              else
                key_tag = attributes_with_guessed_defaults.include?(key) ? 'yellow.bold' : 'yellow'
                value_tag, value_text = highlight(value)
                buffer << ["<#{key_tag}>#{key}:</#{key_tag}> <#{value_tag}>#{value_text}</#{value_tag}>", help[key]]
              end
            end

            longest_item = items.map(&:first).max_by(&:length)
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

        expense = expenses.last
        update_running_total(expenses[0..-2], expense)
        if expense.running_total
          puts "~ Running total for <red>#{expense.payment_method}</red> is <green>#{format_cents_to_money(expense.running_total)}</green>.".colourise(bold: true)
        else
          puts "~ Unknown running total for <red>#{expense.payment_method}</red>.".colourise(bold: true)
        end

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

      def prompt_money(key, prompt)
        @prompt.prompt(key, prompt) do
          validate_raw_value(/^\d+(\.\d{2})?$/)

          clean_value do |raw_value|
            convert_money_to_cents(raw_value)
          end

          validate_clean_value do |clean_value|
            clean_value.integer?
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

        self.init_last_index_cache(attribute, expense.send(attribute))
        @cache[:"last_#{attribute}_index"] += 1

        self.reset_last_index_cache_if_last(attribute)
        self.select_next_if_current_selection_equals_next_item(attribute, expense.send(attribute))

        self.blink_if_starting_over(attribute)
        self.set_expense_attribute_to_selection(expense, attribute)
      end

      def cycle_backwards_between_values(expenses, expense, attribute)
        self.cache_values_for(expenses, attribute)

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

      def most_common_attribute_value(expenses, attribute)
        expenses.map(&attribute).uniq.max_by do |value|
          expenses.count do |expense|
            expense.send(attribute) == value
          end
        end
      end

      def set_currency_based_on_location(expenses, expense)
        location = expense.location

        last_same_location_expense = expenses.reverse.find do |expense|
          expense.location == location
        end

        expense.currency = last_same_location_expense.currency
      end

      def update_payment_method_if_online(expenses, expense)
        most_common_online_payment_method = self.most_common_attribute_value(expenses.select { |expense| expense.location == 'online' }, :payment_method)
        expense.payment_method = most_common_online_payment_method if most_common_online_payment_method
      end

      def update_running_total(expenses, expense)
        return if expense.payment_method == 'cash'

        payment_method = expense.payment_method
        last_expense_with_the_same_payment_method = expenses.reverse.find do |expense|
          expense.payment_method == payment_method
        end

        return unless last_expense_with_the_same_payment_method

        expense.running_total = last_expense_with_the_same_payment_method.running_total - expense.total
      end

      def highlight(value)
        case value
        when Date
          [:magenta, value.strftime('%A %d/%m')]
        when nil
          [:cyan, 'nil']
        when true, false
          [:red, value.to_s]
        when Integer
          [:red, self.format_cents_to_money(value)]
        when String
          [:green, "\"#{value}\""]
        else
          raise value.inspect
        end
      end

      def format_cents_to_money(cents)
        groups = cents.to_s.each_char.group_by.with_index do |char, index|
          index < (cents.to_s.length - 2)
        end

        x = (groups[true] || ['0']).join
        y = groups[false].join unless groups[false].join.match(/^0{1,2}$/)
        [x, y].compact.join('.')
      end
    end
  end
end
