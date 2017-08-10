require 'refined-refinements/curses/app'
require 'refined-refinements/cli/prompt'
require 'expenses/commands/lib/common_prompts'
require 'expenses/ui/commanders/item_commander'
require 'expenses/ui/commanders/tag_commander'
require 'expenses/ui/commanders/expense_commander'
require 'expenses/ui/screens/expense_screen'
require 'expenses/utils'
require 'expenses/query_engine'

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

        qe = QueryEngine.new(@collection)

        App.new.run do |app, window|
          @prompt = RR::Prompt.new do |prompt|
            app.readline(prompt)
          end

          # Required arguments that don't have reasonable defaults,
          # we ask for explicitly.
          prompt_desc
          # prompt_total

          # Here we could guess that if the total is over n, we'd default
          # to the last card payment method, but the problem is that since
          # we don't know the currency yet, we cannot make an assumption
          # whether the purchase was expensive or not.
          most_common_payment_method = Utils.most_common_attribute_value(expenses, :payment_method)

          # total_data = @prompt.data.delete(:total)
          data_input = @prompt.data#.merge(total: total_data[:total])

          data = data_input.merge(
            date: Date.today,
            currency: expenses.last ? expenses.last.currency : 'EUR',
            location: expenses.last ? expenses.last.location : 'online',
            payment_method: most_common_payment_method || 'cash')

          # data.merge!(total_data)
          expense = Expense.new(**data)
          expense.get_exhange_rates # Can we do this in the background?

          if previous_expense = expenses.reverse.find { |e| e.desc == expense.desc }
            expense.tag = qe.attribute_values_with_counts(previous_expense.items).map(&:first).first
            $GUESSED_DEFAULTS = []
          else
            $GUESSED_DEFAULTS = [:tag]
            most_common_tag = qe.tags.first
            expense.tag = most_common_tag || '#groceries'
          end

          # Optional arguments or arguments with reasonable defaults.
          # Can be changed from the commander.
          ExpenseCommander.new(app).run(@collection, expense)

          app.destroy
        end

        report_end_balance(expenses, expenses.last)
        report_budget(expenses, expenses.last)
      rescue Interrupt
        puts; exit
      end

      def report_end_balance(expenses, expense)
        balance = Utils.balance_for(@collection, expense.payment_method, expense.currency)

        payment_method_label = expense.payment_method == 'cash' ? expense.currency : expense.payment_method

        if balance
          puts "<green.bold>~</green.bold> Running total for <cyan.bold>#{payment_method_label}</cyan.bold> is <yellow.bold>#{Utils.format_cents_to_money(balance)}</yellow.bold>.".colourise
        else
          puts "<yellow>~</yellow> Unknown running total for <red>#{payment_method_label}</red>.".colourise
        end
      end

      # TODO: Use total_eur or total_usd.
      # TODO: Use weekly budget.
      def report_budget(expenses, expense)
        require 'ostruct'
        budget = OpenStruct.new(weekly: 30 * 7 + 50, currency: 'EUR')
        # TODO: Cache exchange rates to all currencies.

        qe = QueryEngine.new(@collection)
        items_total = qe.days_items(expense.date).select { |expense| expense.tag != '#long_term' }.sum(&:total)
        tip_and_fee_total = qe.days_expenses(expense.date).sum { |expense| expense.tip + expense.fee }

        day_total = items_total + tip_and_fee_total
        remaining = 7500 - day_total
        if remaining >= 0
          puts "~ Budget remaining: <green>#{Utils.format_cents_to_money(remaining)} PLN</green> out of 75 PLN.".colourise
        else
          puts "~ Budget of 75 PLN presahnut by <red>#{Utils.format_cents_to_money(remaining.abs)} PLN</red>.".colourise
        end
      end
    end
  end
end
