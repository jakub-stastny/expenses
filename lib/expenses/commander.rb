require 'json'
require 'expenses'

module Expenses
  module Commander
    def self.parse(data_file_path)
      raw_data_lines = JSON.parse(File.read(data_file_path))
      raw_data_lines.map do |raw_data_line|
        Expense.deserialise(raw_data_line)
      end
    rescue JSON::ParserError => error
      puts "JSON from #{data_file_path} cannot be parsed:"
      puts error.message
      exit 1
    end

    def self.edit(data_file_path)
      system "#{ENV['EDITOR'] || 'vim'} #{data_file_path}"
    end

    def self.sum(data_file_path)
      data_lines = self.parse(data_file_path)
      data_lines.group_by { |line| line.date.cweek }.each do |week, lines|
        all_types = lines.group_by(&:type).map do |(type, lines)|
          "#{type} #{lines.sum(&:total) / 100}" # TODO: EUR / USD
        end

        date = lines.first.date
        monday = date - (date.wday == 0 ? 7 : date.wday - 1)

        all_currencies = lines.map(&:currency).uniq.map do |currency|
          "#{currency} #{lines.select { |line| line.currency == currency }.sum(&:total) / 100}"
        end

        all_tags = lines.map(&:tag).uniq.map do |tag|
          "#{tag} #{lines.select { |line| line.tag == tag }.sum(&:total) / 100}" # TODO: EUR / USD
        end

        puts "Week #{week} (#{monday.strftime('%d/%m')} – #{(monday + 7).strftime('%d/%m')}):"
        puts "  EUR #{lines.sum(&:total_eur) / 100} | USD #{lines.sum(&:total_usd) / 100} | #{all_currencies.join(', ')}"
        puts "  #{all_tags.join(' ')}" # TODO: Use colours to highlight tags vs. currencies.
        puts "  #{all_types.join(', ')}\n\n"
      end

      puts "Total: #{data_lines.sum(&:total) / 100}" # TODO: EUR / USD / ALL CURRENCIES
    end

    def self.add(data_file_path)
      begin
        expenses = self.parse(data_file_path)
      rescue Errno::ENOENT
        expenses = Array.new
      end

      expense_data = Hash.new

      print "Date (#{Date.today.iso8601}): "
      date = STDIN.readline.chomp
      date = Date.today.iso8601 if date.empty?
      abort "Incorrect format." unless date.match(/^\d{4}-\d{2}-\d{2}$/)
      expense_data[:date] = Date.parse(date)
      # TODO: -1 for yesterday etc.

      print "Types (one of #{Expense::TYPES.join(', ')}): "
      expense_data[:type] = STDIN.readline.chomp
      abort "Invalid type. Types: #{Expense::TYPES.inspect}" unless Expense::TYPES.include?(expense_data[:type])
      # TODO: use indices for selection.

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

      print "Currency (EUR): "
      expense_data[:currency] = STDIN.readline.chomp
      expense_data[:currency] = 'EUR' if expense_data[:currency].empty?

      print "Note: "
      expense_data[:note] = STDIN.readline.chomp

      print "Tag (currently used: #{expenses.map(&:tag).uniq.join(' ')}): "
      expense_data[:tag] = STDIN.readline.chomp

      print "Location (currently used: #{expenses.map(&:location).uniq.join(', ')}): "
      expense_data[:location] = STDIN.readline.chomp

      expenses << Expense.new(**expense_data)

      # We cannot just add, since when we're offline, we save expenses without
      # their total converted to USD/EUR.
      File.open(data_file_path, 'w') do |file|
        file.puts(JSON.pretty_generate(expenses.map(&:serialise)))
      end
    end
  end
end
