module Expenses
  module Commands
    class BalanceCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>add</red> <bright_black># TODO.</bright_black>
      EOF

      def initialize(manager, args)
        @manager, @args = manager, args
      end

      def run
        abort "To be done."
      end
    end
  end
end
