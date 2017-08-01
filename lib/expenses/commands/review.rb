require 'refined-refinements/colours'

module Expenses
  module Commands
    class ReviewCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        # TODO
      EOF

      def initialize(manager, args)
        @manager, @args = manager, args
        @expenses = manager.parse
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

      def expenses_for_review
        expenses.select { |expense|
          expense.type == 'long_term' && expense.metadata.reviews.last[:date] < 3.months.ago
        }
      end
    end
  end
end
