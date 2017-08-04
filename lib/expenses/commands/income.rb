require 'refined-refinements/cli/prompt'
require 'expenses/commands/lib/common_prompts'

module Expenses
  module Commands
    class IncomeCommand < RR::Command
      include CommonPrompts

      self.help = <<-EOF
        #{self.main_command} <green>income</green> <bright_black># Log an income.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args, @prompt = collection, args, RR::Prompt.new
      end

      def run
        prompt_date
        prompt_total
        prompt_account

        @collection.items << Income.new(**@prompt.data)
        @collection.save

        puts "\nIncome item #{@collection.items.last.serialise.inspect} has been saved."
      end
    end
  end
end
