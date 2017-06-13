require 'csv'
require 'expenses'

module Expenses
  module Commander
    def self.edit(path)
      system "vim #{path}"
    end

    def self.sum
      data_lines = parse(data_file_path)
      data_lines.group_by { |line| line.date.cweek }.each do |week, lines|
        details = lines.group_by(&:type).reduce(Hash.new) do |result, (type, lines)|
          result.merge(type => lines.sum(&:total))
        end

        date = lines.first.date
        monday = date - (date.wday == 0 ? 7 : date.wday - 1)
        puts "Week #{week} (#{monday.strftime('%d/%m')} – #{(monday + 7).strftime('%d/%m')}): #{lines.sum(&:total)} (#{details})"
      end

      puts "\nTotal: #{data_lines.sum(&:total)}"
    end

    def self.add
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

      print "Tip: "
      tip = STDIN.readline.chomp
      tip = tip.empty? ? '0' : tip
      abort "Invalid amount." unless total.match(/^\d+(\.\d{2})?$/)

      print "Currency (EUR): "
      currency = STDIN.readline.chomp
      currency = 'EUR' if currency.empty?

      print "Note: "
      note = STDIN.readline.chomp

      expense = Expense.new(date, type, desc, total, tip, currency, note)

      data_lines = parse(data_file_path)
      data_lines << expense

      # TODO: Save.
      # CSV not suited for writing by hand, use cents there?
      # CSV.open("path/to/file.csv", "wb") do |csv|
      CSV.generate do |csv|
        csv << expense.to_csv
        csv << ["another", "row"]
      end
    end
  end
end
