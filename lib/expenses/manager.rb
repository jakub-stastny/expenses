require 'json'
require 'expenses/expense'

module Expenses
  class Manager
    attr_reader :data_file_path
    def initialize(data_file_path)
      @data_file_path = data_file_path
    end

    def parse
      return Array.new if File.empty?(@data_file_path)

      raw_data_lines = JSON.parse(File.read(@data_file_path))
      raw_data_lines.map do |raw_data_line|
        Expense.deserialise(raw_data_line)
      end
    rescue JSON::ParserError => error
      raise JSON::ParserError.new("JSON from #{@data_file_path} cannot be parsed: #{error.message}")
    end

    def items
      @items ||= self.parse
    end

    def filter_type(type_name)
      self.items.select do |item|
        item.type == type_name
      end
    end

    def expenses
      self.filter_type(:expense)
    end

    def withdrawals
      self.filter_type(:withdrawal)
    end

    def income_items
      self.filter_type(:income)
    end

    def save(expenses)
      final_json = JSON.pretty_generate(expenses.map(&:serialise))
      File.open(@data_file_path, 'w') do |file|
        file.puts(final_json)
      end
    end
  end
end
