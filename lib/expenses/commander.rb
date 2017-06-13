require 'csv'
require 'expenses'

module Expenses
  module Commander
    def self.parse(data_file_path)
      raw_data_lines = CSV.read(data_file_path, converters: [:date, :numeric])
      raw_data_lines.map { |line| Expense.new(*line) }
    end

    def self.edit(data_file_path)
      system "#{ENV['EDITOR'] || 'vim'} #{data_file_path}"
    end

    def self.sum(data_file_path)
      data_lines = self.parse(data_file_path)
      data_lines.group_by { |line| line.date.cweek }.each do |week, lines|
        details = lines.group_by(&:type).reduce(Hash.new) do |result, (type, lines)|
          result.merge(type => lines.sum(&:total) / 100)
        end

        date = lines.first.date
        monday = date - (date.wday == 0 ? 7 : date.wday - 1)
        puts "Week #{week} (#{monday.strftime('%d/%m')} – #{(monday + 7).strftime('%d/%m')}): #{lines.sum(&:total) / 100} (#{details})"
      end

      puts "\nTotal: #{data_lines.sum(&:total) / 100}"
    end

    def self.add(data_file_path)
      expenses = self.parse(data_file_path)

      print "Date (#{Date.today.iso8601}): "
      date = STDIN.readline.chomp
      date = Date.today.iso8601 if date.empty?
      abort "Incorrect format." unless date.match(/^\d{4}-\d{2}-\d{2}$/)
      date = Date.parse(date)

      print "Types (one of #{Expense::TYPES.invert.keys.join(', ')}): "
      type = STDIN.readline.chomp.upcase
      abort "Invalid type. Types: #{Expense::TYPES.inspect}" unless Expense::TYPES.invert.include?(type)

      print "Description: "
      desc = STDIN.readline.chomp

      print "Total: "
      total = STDIN.readline.chomp
      abort "Invalid amount." unless total.match(/^\d+(\.\d{2})?$/)
      total = (total.match(/\./) ? total.delete('.') : "#{total}00").to_i # Convert to cents.

      print "Tip: "
      tip = STDIN.readline.chomp
      tip = tip.empty? ? '0' : tip
      abort "Invalid amount." unless tip.match(/^\d+(\.\d{2})?$/)
      tip = (tip.match(/\./) ? tip.delete('.') : "#{tip}00").to_i # Convert to cents.

      print "Currency (EUR): "
      currency = STDIN.readline.chomp
      currency = 'EUR' if currency.empty?

      print "Note: "
      note = STDIN.readline.chomp

      expense = Expense.new(date, type, desc, total, tip, currency, note)
      expenses << expense

      # We cannot just add, since when we're offline, we save expenses without
      # their total converted to USD/EUR.
      CSV.open(data_file_path, 'w') do |csv|
        expenses.each do |expense|
          csv << expense.serialise
        end
      end
    end
  end
end
