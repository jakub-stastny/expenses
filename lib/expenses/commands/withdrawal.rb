require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class WithdrawalCommand < RR::Command
      self.help = <<-EOF
        # TODO
      EOF

      def initialize(manager, args)
        @manager, @args, @prompt = manager, args, RR::Prompt.new
      end

      def run
        begin
          expenses = @manager.parse
        rescue Errno::ENOENT
          expenses = Array.new
        end

        prompt_date
        prompt_total
        prompt_location(expenses)
        prompt_currency(expenses)
        prompt_note

        expenses << Expense.new(**@prompt.data)

        @manager.save(expenses)

        puts "\nExpense #{expenses.last.serialise.inspect} has been saved."
      rescue Interrupt
        puts; exit
      end

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

      def prompt_type
        @prompt.prompt(:type, 'Type', options: Expense::TYPES) do
          clean_value do |raw_value|
            self.retrieve_by_index_or_self_if_on_the_list(Expense::TYPES, raw_value)
          end

          validate_clean_value do |clean_value|
            Expense::TYPES.include?(clean_value)
          end
        end
      end

      def prompt_desc
        @prompt.prompt(:desc, 'Description') do
          clean_value { |raw_value| raw_value }

          validate_clean_value do |clean_value|
            clean_value && ! clean_value.empty?
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

      def prompt_tip
        @prompt.prompt(:tip, 'Tip') do
          validate_raw_value(/^\d+(\.\d{2})?$/, allow_empty: true)

          clean_value do |raw_value|
            convert_money_to_cents(raw_value)
          end
        end
      end

      def prompt_currency(expenses)
        currencies = expenses.map(&:currency).uniq
        @prompt.prompt(:currency, 'Currency code', options: currencies, default: expenses.last.currency) do
          clean_value do |raw_value|
            (not raw_value.empty?) ? self.self_or_retrieve_by_index(currencies, raw_value) : expenses.last.currency
          end

          validate_clean_value do |clean_value|
            clean_value.match(/^[A-Z]{3}$/)
          end
        end
      end

      def prompt_note
        @prompt.prompt(:note, 'Note') do
          clean_value { |raw_value| raw_value }
        end
      end

      def prompt_tag(expenses)
        tags = expenses.map(&:tag).uniq.compact.sort # TODO: Sort by number of occurences.
        comp = Proc.new { |s| tags.grep(/^#{Regexp.escape(s)}/) }

        @prompt.set_completion_proc(comp) do
          @prompt.prompt(:tag, 'Tag', help: 'use tab completion') do
            clean_value do |raw_value|
              raw_value.strip
            end

            validate_clean_value do |clean_value|
              clean_value.match(/^#[a-z_]+$/)
            end
          end
        end
      end

      def prompt_location(expenses)
        locations = expenses.map(&:location).uniq.compact
        @prompt.prompt(:location, 'Location', options: locations, default: expenses.last.location) do
          clean_value do |raw_value|
            (not raw_value.empty?) ? self.self_or_retrieve_by_index(locations, raw_value) : expenses.last.location
          end

          validate_clean_value do |clean_value|
            clean_value && ! clean_value.empty?
          end
        end
      end
    end
  end
end
