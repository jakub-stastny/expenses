require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class IncomeCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <red>income</red> <bright_black># TODO.</bright_black>
      EOF

      def initialize(manager, args)
        @manager, @args, @prompt = manager, args, RR::Prompt.new
      end

      def run
        begin
          expenses = @manager.parse
        rescue Errno::ENOENT
          expenses = Array.new
        end

        # TODO
      end
    end
  end
end
