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

    def self.edit(data_file_path)
      system "#{ENV['EDITOR'] || 'vim'} #{data_file_path}"
    end

    def self.report(data_file_path)
      require 'expenses/commands/report'
      Expenses::Commands::Report.run(data_file_path)
    end

    def self.review(data_file_path)
      # TODO
    end

    def self.console(data_file_path)
      # TODO
    end

    def self.add(data_file_path)
      require 'expenses/commands/add'
      Expenses::Commands::Add.run(data_file_path)
    end
  end
end
