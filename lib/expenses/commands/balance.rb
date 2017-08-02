require 'flashcards/utils'

module Expenses
  module Commands
    class BalanceCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>balance</red> <bright_black># Show balances of your accounts and available cash funds.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      def run
        accounts = @collection.balances.map(&:account)
        cash_currencies = @collection.withdrawals.map(&:currency)

        account_balances_text = accounts.map { |account_name|
          balance = Utils.balance_for(@collection, account_name)
          "<yellow>#{account_name}</yellow> #{Utils.format_cents_to_money(balance)}"
        }.join("\n")

        cash_available_text = cash_currencies.map { |currency|
          balance = Utils.balance_for(@collection, 'cash', currency)
          "<yellow>#{currency}</yellow> #{Utils.format_cents_to_money(balance)}"
        }.join("\n")

        puts <<-EOF.colourise.gsub(/^ */, '')
          <green.bold>Account balances</green.bold>
          #{account_balances_text}

          <green.bold>Cash available</green.bold>
          #{cash_available_text}

          # TODO: Overall balance in EUR / USD.
        EOF
      end
    end
  end
end
