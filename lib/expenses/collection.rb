# frozen_string_literal: true

require 'json'
require 'expenses/models/loggable_item'
require 'expenses/models/expense'
require 'refined-refinements/collection'

module Expenses
  class Collection < RR::Collection
    def self.data_file_dir
      Pathname.new("~/Dropbox/Data/Data/Expenses").expand_path
    end

    attr_reader :path
    def initialize(basename)
      @path = self.class.data_file_dir.join(basename)
      @activity_filters = Hash.new
    end

    def items
      super do |data|
        LoggableItem.deserialise(data)
      end
    end

    def all_expenses
      self.filter_type(BaseExpense)
    end

    def expenses
      self.filter_type(Expense)
    end

    def deposits
      self.filter_type(Deposit)
    end

    def withdrawals
      self.filter_type(Withdrawal)
    end

    def balances
      self.filter_type(Balance)
    end

    def income_items
      self.filter_type(Income)
    end

    def rides
      self.filter_type(Ride)
    end

    protected
    def filter_type(type_name)
      self.items.select do |item|
        type_name === item
      end
    end

    def deserialise(path)
      return Array.new if File.empty?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError => error
      raise JSON::ParserError, "JSON from #{path} cannot be parsed: #{error.message}"
    end

    def serialise
      JSON.pretty_generate(self.items.map(&:serialise))
    end
  end
end
