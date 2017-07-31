require 'refined-refinements/colours'

module Expenses
  module Commands
    class Last
      using RR::ColourExts

      def initialize(manager)
        @manager, @expenses = manager, manager.parse
      end

      def run
        unless @expenses.empty?
          puts "Last day items:".colourise(bold: true)
          @expenses.each do |expense|
            if expense.date == @expenses.last.date
              puts "- #{expense.desc}"
            end
          end
        else
          puts "<red>The are no expenses yet.</red>".colourise
        end
      end
    end
  end
end
