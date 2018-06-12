# frozen_string_literal: true

module Expenses
  module Commands
    class ConsoleCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <green>console</green> <bright_black># Open Ruby console with expenses loaded.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      def run
        # Console usage:
        # @collection.expenses.last.currency = 'EUR'
        # @collection.save
        require 'pry'; binding.pry
      end
    end
  end
end
