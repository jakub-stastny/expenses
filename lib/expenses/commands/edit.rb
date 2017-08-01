module Expenses
  module Commands
    class EditCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>balance</red> [word] [translations]
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
