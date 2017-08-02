require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class IncomeCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <green>income</green> <bright_black># Log an income.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args, @prompt = collection, args, RR::Prompt.new
      end

      def run
        prompt_date
        prompt_total
        prompt_account

        @collection.items << Income.new(**@prompt.data)
        @collection.save

        puts "\nIncome item #{@collection.items.last.serialise.inspect} has been saved."
      end

      private
      def prompt_date
        help = "<green>#{Date.today.iso8601}</green>, anything that <magenta>Data.parse</magenta> parses or <magenta>-1</magenta> for yesterday etc"
        @prompt.prompt(:date, 'Date', help: help) do
          clean_value do |raw_value|
            case raw_value
            when /^$/ then Date.today
            when /^-(\d+)$/ then Date.today - $1.to_i
            else Date.parse(raw_value) end
          end

          validate_clean_value do |clean_value|
            clean_value.is_a?(Date)
          end
        end
      end

      def prompt_total
        @prompt.prompt(:total, 'Total') do
          validate_raw_value(/^\d+(\.\d{2})?$/)

          clean_value do |raw_value|
            convert_money_to_cents(raw_value)
          end

          validate_clean_value do |clean_value|
            clean_value.integer?
          end
        end
      end

      def prompt_account
        accounts = @collection.balances.map(&:account).uniq

        last_income_item = @collection.income_items.last
        default = last_income_item.account if last_income_item

        @prompt.prompt(:account, 'Account', options: accounts, default: default) do
          clean_value do |raw_value|
            if raw_value.empty?
              default
            else
              self.retrieve_by_index_or_self_if_on_the_list(accounts, raw_value)
            end
          end
        end
      end
    end
  end
end
