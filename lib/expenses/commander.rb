require 'json'
require 'expenses'

module Expenses
  module Commander
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

      Expenses::Commands::Add.new(data_file_path).run do
        self.parse(data_file_path)
      end
    end

    def self.report(data_file_path)
      require 'expenses/commands/report'
      Expenses::Commands::Report.new(self.parse(data_file_path)).run
    end

    def self.review(data_file_path)
      require 'expenses/commands/review'
      Expenses::Commands::Review.new(self.parse(data_file_path)).run
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
