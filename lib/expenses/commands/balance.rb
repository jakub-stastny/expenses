# frozen_string_literal: true

require 'flashcards/utils'

module Expenses
  module Commands
    class BalanceCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <green>balance</green> <bright_black># Show balances of your accounts and available cash funds.</bright_black>
        #{self.main_command} <red>balance</red> [account_name] [value] <bright_black># Set the current balance of given account.</bright_black>
        #{self.main_command} <red>balance</red> [currency] [value] <bright_black># Set the current balance of cash funds.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      def run
        case @args.length
        when 0 then self.report_balances
        when 2 then self.set_balance(*@args)
        else
          raise ShowHelpError.new
        end
      end

      def set_balance(account_name_or_currency, balance)
        cents = Utils.money_to_cents(balance)

        if @collection.balances.map(&:account).include?(account_name_or_currency)
          # What if it doesn't match with the value from the system? Should we
          # create an expense (negative or positive) behind the scene to indicate
          # the real state of things?
          puts "TODO"
        elsif @collection.withdrawals.map(&:currency).include?(account_name_or_currency)
          # Can we do this? Before it'd be done in withdrawals.
          puts "TODO"
        else
          raise 'x'
        end
      end

      def report_balances
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
