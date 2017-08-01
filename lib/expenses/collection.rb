require 'json'
require 'expenses/loggable_item'
require 'expenses/expense'
require 'refined-refinements/collection'

module Expenses
  class Collection < RR::Collection
    def self.data_file_dir
      Pathname.new("~/Dropbox/Data/Data/Expenses").expand_path
    end

    def initialize(basename)
      @path = self.class.data_file_dir.join(basename)
      @activity_filters = Hash.new
    end

    def items
      super do |data|
        LoggableItem.deserialise(data)
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

    protected
    def filter_type(type_name)
      self.items.select do |item|
        item.type == type_name
      end
    end

    def deserialise(path)
      return Array.new if File.empty?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError => error
      raise JSON::ParserError.new("JSON from #{path} cannot be parsed: #{error.message}")
    end

    def serialise
      JSON.pretty_generate(self.items.map(&:serialise))
    end
  end
end
