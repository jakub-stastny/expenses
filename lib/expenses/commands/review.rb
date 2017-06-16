require 'refined-refinements/colours'

module Expenses
  module Commands
    module Review
      using RR::ColourExts

      def self.run(data_lines)
        abort 'This is not yet implemented.'

        expenses = self.parse(data_file_path)
        expenses_for_review = expenses.select { |expense| expense.should_be_reviewed? }
        expenses_for_review.each do
          puts "Was #{expense.desc} worth €#{expense.total_eur}? (yes/no/not sure): "
          STDIN.readline
          puts "Any comments? "
          STDIN.readline
        end
      end
    end
  end
end
