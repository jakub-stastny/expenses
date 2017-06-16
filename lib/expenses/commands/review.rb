require 'refined-refinements/colours'

module Expenses
  module Commands
    class Review
      using RR::ColourExts

      def initialize(expenses)
        @expenses = expenses
      end

      def run
        abort 'This is not yet implemented.'

        self.expenses_for_review.each do
          puts "Was #{expense.desc} worth €#{expense.total_eur}? (yes/no/not sure): "
          STDIN.readline
          puts "Any comments? "
          STDIN.readline
        end
      end

      def self.expenses_for_review
        expenses.select { |expense|
          expense.type == 'long_term' && expense.metadata.reviews.last[:date] < 3.months.ago
        }
      end
    end
  end
end
