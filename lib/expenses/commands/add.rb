require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class Add
      def initialize(data_file_path)
        @data_file_path, @prompt = data_file_path, RR::Prompt.new
      end

      def run(&parse_expenses_block)
        expenses = get_expenses(&parse_expenses_block)

        # prompt_date
        # prompt_type
        # prompt_total
        # prompt_tip
        prompt_currency(expenses)
        # prompt_note
        # prompt_tag(expenses)
        # prompt_location(expenses)
        exit ###

        expenses << validate_expense(@prompt.data)
        save_expenses(expenses)
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
        @prompt.prompt(:currency, 'Currency code', options: currencies) do
          clean_value do |raw_value|
            self.retrieve_by_index_or_self_if_on_the_list(currencies, raw_value)
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
        tags = expenses.map(&:tag).uniq
        tag_help = "currently used: #{self.show_label_for_self_or_retrieve_by_index(tags)}" unless tags.empty?
        @prompt.prompt(:tag, 'Tag', help: tag_help) do
          clean_value do |raw_value|
            self.self_or_retrieve_by_index(tags, raw_value)
          end
        end
      end

      def prompt_location(expenses)
        locations = expenses.map(&:location).uniq
        location_help = " (currently used: #{self.show_label_for_self_or_retrieve_by_index(locations)})" unless locations.empty?
        print "Location#{location_help}: "
        @prompt.prompt(:location, 'Location', help: location_help) do
          clean_value do |raw_value|
            self.self_or_retrieve_by_index(tags, raw_value)
          end

          validate_clean_value do |clean_value|
            ! clean_value.empty?
          end
        end
      end

      def get_expenses(&parse_expenses_block)
        parse_expenses_block.call
      rescue Errno::ENOENT
        Array.new
      end

      # This is to get rid of empty values through serialise, so the validations catches up all errors.
      def validate_expense(data)
        expense = Expense.new(**expense_data)
        return Expense.deserialise(expense.serialise)
      rescue => error
        # Load pry, so you can fix it. Press Ctrl+d to save.
        try_to_load_console
      ensure
        puts; p expenses.last
      end

      def save_expenses(expenses)
        final_json = JSON.pretty_generate(expenses.map(&:serialise))
        File.open(@data_file_path, 'w') do |file|
          file.puts(final_json)
        end
      end

      def try_to_load_console
        require 'pry'; binding.pry
      rescue LoadError
      end
    end
  end
end
