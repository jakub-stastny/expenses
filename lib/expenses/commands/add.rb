require 'refined-refinements/colours'

module Expenses
  module Commands
    class Add
      using RR::ColourExts

      def initialize(data_file_path)
        @data_file_path = data_file_path
      end

      def run(&parse_expenses_block)
        begin
          expenses = parse_expenses_block.call
        rescue Errno::ENOENT
          expenses = Array.new
        end

        expense_data = Hash.new

        print "<bold>Date</bold> (<green>#{Date.today.iso8601}</green> or input date or use <magenta>-1</magenta> for yesterday etc): ".colourise
        date = STDIN.readline.chomp
        date = if date.empty?
          Date.today.iso8601
        elsif date.match(/^-(\d)/)
          (Date.today - $1.to_i).iso8601
        else
          date
        end

        abort "Incorrect format." unless date.match(/^\d{4}-\d{2}-\d{2}$/)
        expense_data[:date] = Date.parse(date)

        print "Types (one of #{self.show_label_for_self_or_retrieve_by_index(Expense::TYPES)}): "
        expense_data[:type] = self.self_or_retrieve_by_index(Expense::TYPES, STDIN.readline.chomp)
        abort "Invalid type. Types: #{Expense::TYPES.inspect}" unless Expense::TYPES.include?(expense_data[:type])

        print "Description: "
        expense_data[:desc] = STDIN.readline.chomp
        # TODO: validate presence

        print "Total: "
        total = STDIN.readline.chomp
        abort "Invalid amount." unless total.match(/^\d+(\.\d{2})?$/)
        expense_data[:total] = (total.match(/\./) ? total.delete('.') : "#{total}00").to_i # Convert to cents.
        # TODO: validate presence

        print "Tip: "
        tip = STDIN.readline.chomp
        tip = tip.empty? ? '0' : tip
        abort "Invalid amount." unless tip.match(/^\d+(\.\d{2})?$/)
        expense_data[:tip] = (tip.match(/\./) ? tip.delete('.') : "#{tip}00").to_i # Convert to cents.

        currencies = expenses.map(&:currency).uniq
        print "Currency (#{self.show_label_for_self_or_retrieve_by_index(currencies)}): "
        expense_data[:currency] = self.self_or_retrieve_by_index(currencies, STDIN.readline.chomp, 'EUR')

        print "Note: "
        expense_data[:note] = STDIN.readline.chomp

        tags = expenses.map(&:tag).uniq
        print "Tag (currently used: #{self.show_label_for_self_or_retrieve_by_index(tags)}): "
        expense_data[:tag] = self.self_or_retrieve_by_index(tags, STDIN.readline.chomp)

        locations = tags = expenses.map(&:location).uniq
        print "Location (currently used: #{self.show_label_for_self_or_retrieve_by_index(locations)}): "
        expense_data[:location] = self.self_or_retrieve_by_index(locations, STDIN.readline.chomp)

        expenses << Expense.new(**expense_data)

        final_json = JSON.pretty_generate(expenses.map(&:serialise))
        File.open(@data_file_path, 'w') do |file|
          file.puts(final_json)
        end
      end

      def self_or_retrieve_by_index(list, input, default_value = nil)
        if input.match(/^\d+$/)
          list[input.to_i]
        elsif input.empty?
          default_value
        else
          input
        end
      end

      def show_label_for_self_or_retrieve_by_index(list)
        list.map.with_index { |key, index|
          "<green>#{key}</green> <magenta>#{index}</magenta>"
        }.join(' ').colourise
      end
    end
  end
end
