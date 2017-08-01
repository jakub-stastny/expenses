module Expenses
  module Commands
    class ConsoleCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <red>console</red> <bright_black># Open Ruby console with expenses loaded.</bright_black>
      EOF

      def initialize(manager, args)
        @manager, @args = manager, args
      end

      # Console usage:
      # expenses = @manager.parse
      # @manager.save(expenses)
      def run
        require 'pry'; binding.pry
      end
    end
  end
end
