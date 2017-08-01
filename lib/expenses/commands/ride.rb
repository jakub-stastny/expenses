require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class RideCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <red>ride</red> <bright_black># TODO.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args, @prompt = collection, args, RR::Prompt.new
      end

      def run
        begin
          expenses = @collection.expenses
        rescue Errno::ENOENT
          expenses = Array.new
        end

        # TODO
      end
    end
  end
end
