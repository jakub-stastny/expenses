require 'refined-refinements/cli/prompt'
require 'expenses/commands/lib/common_prompts'

module Expenses
  module Commands
    class WithdrawalCommand < RR::Command
      include CommonPrompts

      self.help = <<-EOF
        #{self.main_command} <red>withdrawal</red> <bright_black># Log cash withdrawal.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args, @prompt = collection, args, RR::Prompt.new
      end

      def run
        prompt_date
        prompt_total
        # currency:, account:, location:, balance:
        prompt_location
        prompt_currency
        prompt_note
        # fee

        expenses << Withdrawal.new(**@prompt.data)

        @collection.save

        puts "\nWithdrawal #{@collection.items.last.serialise.inspect} has been saved."
      rescue Interrupt
        puts; exit
      end
    end
  end
end
