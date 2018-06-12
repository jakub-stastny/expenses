# frozen_string_literal: true

require 'refined-refinements/colours'

# 1. Review and correct balances, either by adding missing items or calling BalanceCommand.
# 2. Review long-term and expensive purchases. (these might have dates, so we review them after they happen).
# 3. Show expired deposits.
module Expenses
  module Commands
    class ReviewCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>review</red> <bright_black># TODO.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
        @expenses = collection.expenses
      end

      def report_expired_deposits
        expired_deposits = @collection.deposits.select do |deposit|
          deposit.status == 'open' && deposit.expiration_date < Date.today
        end

        unless expired_deposits.empty?
          puts "<red>You have expired deposits:</red>".colourise(bold: true)
        end

        expired_deposits.each do |deposit|
          puts "- <yellow>#{deposit.desc}</yellow> #{deposit.currency} #{Utils.format_cents_to_money(deposit.total)}".colourise
        end
      end

      def run
        self.report_expired_deposits

        self.expenses_for_review.each do
          puts "Was #{expense.desc} worth €#{expense.total_eur}? (yes/no/not sure): "
          STDIN.readline
          puts "Any comments? "
          STDIN.readline
        end
      end

      def expenses_for_review
        expenses.select { |expense|
          expense.type == 'long_term' && expense.metadata.reviews.last[:date] < 3.months.ago
        }
      end
    end
  end
end
