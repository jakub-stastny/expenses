require 'json'
require 'expenses'
require 'refined-refinements/colours'

module Expenses
  module Commander
    using RR::ColourExts

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

    # Commands.
    def self.add(data_file_path)
      require 'expenses/commands/add'

      Expenses::Commands::Add.run(data_file_path) do
        self.parse(data_file_path)
      end
    end

    def self.report(data_file_path)
      require 'expenses/commands/report'
      Expenses::Commands::Report.run(self.parse(data_file_path))
    end

    # TODO: This is unfinished.
    def self.review(data_file_path)
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

    def self.console(data_file_path)
      require 'pry'
      expenses = self.parse(data_file_path)
      binding.pry
    end

    def self.edit(data_file_path)
      system(ENV['EDITOR'] || 'vim', data_file_path)
    end
  end
end
