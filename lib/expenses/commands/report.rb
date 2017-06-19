require 'refined-refinements/colours'

module Expenses
  module Commands
    class Report
      using RR::ColourExts

      def initialize(manager)
        @manager, @expenses = manager, manager.parse
      end

      def run
        unless @expenses.all? { |expense| expense.total_eur && expense.total_usd }
          abort "Amounts in EUR/USD are missing for some expenses. Connect to the internet."
        end

        print_weekly_report
        print_location_report

        puts "\n<bold>Total:</bold> #{self.report_in_all_currencies(@expenses)}".colourise

        # Save to persist addition of missing total EUR/USD.
        # We cannot do so conditionally, as expenses are already loaded with these values
        # even if they are not present in the expense file, so comparison is pointless.
        @manager.save(@expenses)
      end

      def print_weekly_report
        @expenses.group_by { |line| line.date.cweek }.each do |week, lines|
          date = lines.first.date
          monday = date - (date.wday == 0 ? 7 : date.wday - 1)

          puts "<green>Week #{monday.strftime('%d/%m')} – #{(monday + 7).strftime('%d/%m')}</green>:".colourise(bold: true)
          self.report(lines); puts

          if monday.month != (monday + 7).month
            expenses = @expenses.select { |expense| expense.date.year == monday.year && expense.date.month == monday.month }
            puts "<blue>#{monday.strftime('%B')} #{monday.year}</blue>:".colourise(bold: true)
            self.report(expenses)
          end
        end
      end

      def print_location_report
        puts "<blue>Spendings per location:</blue>".colourise(bold: true)
        @expenses.map(&:location).uniq.each do |location|
          x = report_currencies(spendings_per_location[location][:expenses]) do |amount|
            amount / spendings_per_location[location][:days]
          end
          puts "~ <yellow.bold>#{location}</yellow.bold> #{self.report_currencies(@expenses)} (per day: #{x})".colourise
        end
      end

      def spendings_per_location
        results = Hash.new do |hash, key|
          hash[key] = {days: 0, expenses: Array.new}
        end

        @expenses.each.with_index do |expense, index|
          next if index == 0
          previous_expense = @expenses[index - 1]
          if previous_expense.location == expense.location
            days = (expense.date - previous_expense.date).to_i
            results[expense.location][:days] += days
            results[expense.location][:expenses] << expense
          end
        end

        results
      end

      def report(expenses)
        all_tags = expenses.group_by(&:tag).map do |tag, expenses|
          "<cyan>#{tag}</cyan> #{self.report_currencies(expenses)}"
        end

        all_types = expenses.group_by(&:type).map do |type, expenses|
          "<magenta>#{type}</magenta> #{self.report_currencies(expenses)}"
        end

        puts "<bold>Spendings by tags:</bold> #{all_tags.join(' ')}".colourise
        puts "<bold>Spendings by category:</bold> #{all_types.join(' ')}".colourise
        puts "<bold>Total:</bold> #{self.report_in_all_currencies(expenses)}".colourise
        # Dividing by 7 is inacurate if the week hasn't finished yet.
        date = expenses.last.date
        if Date.today.cweek == date.cweek
          divide_by = (date.wday == 0) ? 7 : date.wday
        else
          divide_by = 7
        end
        puts "<bold>Per day:</bold> #{self.report_currencies(expenses) { |amount| amount / divide_by }}".colourise
      end

      def report_in_all_currencies(expenses)
        all_currencies = expenses.map(&:currency).uniq.map do |currency|
          "#{currency} #{expenses.select { |line| line.currency == currency }.sum(&:total) / 100.0}"
        end

        "#{all_currencies.join(', ')} (total <underline>€#{expenses.sum(&:total_eur) / 100.0}</underline> <underline>$#{expenses.sum(&:total_usd) / 100.0})</underline>"
      end

      def report_currencies(expenses, &block)
        block = Proc.new { |amount| amount } if block.nil?
        "<underline>€#{block.call(expenses.sum(&:total_eur)) / 100.0}</underline> <underline>$#{block.call(expenses.sum(&:total_usd)) / 100.0}</underline>"
      end
    end
  end
end
