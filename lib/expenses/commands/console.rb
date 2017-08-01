module Expenses
  module Commands
    class ConsoleCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <red>console</red> <bright_black># Open Ruby console with expenses loaded.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      # Console usage:
      # expenses = @collection.expenses
      # @collection.save(expenses)
      def run
        require 'pry'; binding.pry
      end
    end
  end
end
