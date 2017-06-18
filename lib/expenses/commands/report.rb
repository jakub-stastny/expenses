require 'refined-refinements/colours'

module Expenses
  module Commands
    class Report
      using RR::ColourExts

      def initialize(expenses)
        @expenses = expenses
      end

      def run
        unless @expenses.all? { |expense| expense.total_eur && expense.total_usd }
          abort "Amounts in EUR/USD are missing for some expenses. Connect to the internet."
        end

        @expenses.group_by { |line| line.date.cweek }.each do |week, lines|
          date = lines.first.date
          monday = date - (date.wday == 0 ? 7 : date.wday - 1)

          puts "<green>Week #{monday.strftime('%d/%m')} – #{(monday + 7).strftime('%d/%m')}</green>:".colourise(bold: true)
          self.report(lines); puts

          if monday.month != (monday + 7).month
            expenses = @expenses.select { |expense| expense.date.year == monday.year && expense.date.month == monday.month }
            puts "<blue>#{monday.strftime('%B')} #{monday.year}</blue>:".colourise(bold: true)
            self.report(expenses)
            self.report_locations(expenses); puts
          end
        end

        puts "<bold>Total:</bold> #{self.report_in_all_currencies(@expenses)}".colourise
      end

      def report(expenses)
        all_tags = expenses.map(&:tag).uniq.map do |tag|
          "<cyan>#{tag}</cyan> #{self.report_currencies(expenses)}"
        end

        all_types = expenses.group_by(&:type).map do |type, expenses|
          "<magenta>#{type}</magenta> #{self.report_currencies(expenses)}"
        end

        puts "<bold>Spendings by tags:</bold> #{all_tags.join(' ')}".colourise
        puts "<bold>Spendings by category:</bold> #{all_types.join(' ')}".colourise
        puts "<bold>Total:</bold> #{self.report_in_all_currencies(expenses)}".colourise
      end

      def report_locations(expenses)
        all_locations = expenses.group_by(&:location).map do |location, expenses|
          "<yellow>#{location}</yellow> #{self.report_currencies(expenses)}"
        end

        puts "<bold>Locations:</bold> #{all_locations.join(' ')}".colourise
      end

      def report_in_all_currencies(expenses)
        all_currencies = expenses.map(&:currency).uniq.map do |currency|
          "#{currency} #{expenses.select { |line| line.currency == currency }.sum(&:total) / 100}"
        end

        "#{all_currencies.join(', ')} (total <underline>€#{expenses.sum(&:total_eur) / 100}</underline> <underline>$#{expenses.sum(&:total_usd) / 100})</underline>"
      end

      def report_currencies(expenses)
        "<underline>€#{expenses.sum(&:total_eur) / 100}</underline> <underline>$#{expenses.sum(&:total_usd) / 100}</underline>"
      end
    end
  end
end
