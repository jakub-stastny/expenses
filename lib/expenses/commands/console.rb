module Expenses
  module Commands
    class ConsoleCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>balance</red> [word] [translations]
      EOF

      def initialize(manager, args)
        @manager, @args = manager, args
      end

      def run
        require 'pry'; binding.pry
      end
    end
  end
end
