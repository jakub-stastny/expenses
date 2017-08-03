require 'refined-refinements/colours'
require 'expenses/utils'

module Expenses
  module Commands
    class LastCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <green>last</green> <bright_black># Show expenses of the last three logged days.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      def run
        expenses = @collection.all_expenses
        unless expenses.empty?
          last_three_logged_days = expenses.map(&:date).uniq[-3..-1]
          last_three_logged_days.each.with_index do |date, index|
            puts "#{"\n" unless index == 0}<green>#{date.strftime("%A %d/%m")}</green>".colourise
            dates_expenses = expenses.select do |expense|
              expense.date == date
            end

            dates_expenses.each do |expense|
              puts "- #{expense.desc} <yellow>#{expense.currency} #{Utils.format_cents_to_money(expense.total)}</yellow>".colourise
            end
            puts "  <bold>Total:</bold> #{Utils.format_cents_to_money(dates_expenses.sum(&:total))}".colourise # TODO: different currencies?
          end
        else
          puts "<red>The are no expenses yet.</red>".colourise
        end
      end
    end
  end
end
