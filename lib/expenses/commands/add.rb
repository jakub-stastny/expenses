require 'refined-refinements/curses/app'
require 'refined-refinements/cli/prompt'
require 'expenses/commands/lib/common_prompts'
require 'expenses/commands/commanders/item'
require 'expenses/commands/commanders/tag'
require 'expenses/commands/commanders/expense'
require 'expenses/commands/commanders/expense_screen'
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
          ExpenseCommander.new(app).run(expenses, expense)

          app.destroy
        end

        report_end_balance(expenses)
      rescue Interrupt
        puts; exit
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
    end
  end
end
