require 'expenses/commands/lib/common_prompts'

module Expenses
  class CommanderMode
    using RR::ColourExts
    include CommonPrompts

    def run(commander, app, prompt, object)
      commander.command('e') do |commander_window|
        prompt = self.prompt_proc(app, commander_window)

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
          object.send("#{attribute}=", new_value)
        else
          # log ...
        end
      end
    end

    def cache
      @cache ||= Hash.new
    end

    def cache_values_for(expenses, attribute) # TODO: clear when new one is added (i. e. using the e command).
      self.cache[:"values_for_#{attribute}"] ||= begin
        expenses.map(&attribute).uniq.sort_by { |value|
          expenses.count { |expense| expense.send(attribute) == value }
        }.reverse
      end
    end

    def init_last_index_cache(attribute, value)
      self.cache[:"last_#{attribute}_index"] ||= begin
        cached_values = self.cache[:"values_for_#{attribute}"]
        value == cached_values.first ? 0 : -1
      end
    end

    def reset_last_index_cache_if_last(attribute)
      if self.cache[:"last_#{attribute}_index"] == self.cache[:"values_for_#{attribute}"].length
        self.cache[:"last_#{attribute}_index"] = 0
      end
    end

    def select_next_if_current_selection_equals_next_item(attribute, current_item)
      current_index = self.cache[:"values_for_#{attribute}"].index(current_item)
      if current_index == self.cache[:"last_#{attribute}_index"]
        self.cache[:"last_#{attribute}_index"] += 1
      end
    end

    def blink_if_starting_over(attribute)
      if self.cache[:"last_#{attribute}_index"] == 0
        # TODO: Blink when starting the next circle.
      end
    end

    def set_expense_attribute_to_selection(expense, attribute)
      values = self.cache[:"values_for_#{attribute}"]
      expense.send(:"#{attribute}=", values[self.cache[:"last_#{attribute}_index"]])
    end

    def cycle_between_values(expenses, expense, attribute)
      self.cache_values_for(expenses, attribute)
      _cycle_between_values(expense, attribute)
    end

    def _cycle_between_values(expense, attribute)
      self.init_last_index_cache(attribute, expense.send(attribute))
      self.cache[:"last_#{attribute}_index"] += 1

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
      self.cache[:"last_#{attribute}_index"] -= 1

      if self.cache[:"last_#{attribute}_index"] < 0
        self.cache[:"last_#{attribute}_index"] = self.cache[:"values_for_#{attribute}"].length + self.cache[:"last_#{attribute}_index"]
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
  end
end
