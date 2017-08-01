require 'refined-refinements/colours'

module Expenses
  module Commands
    class LastCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>last</red> <bright_black># TODO.</bright_black>
      EOF

      def initialize(manager, args)
        @manager, @args = manager, args
      end

      def run
        expenses = manager.parse
        unless expenses.empty?
          puts "Last day items:".colourise(bold: true)
          expenses.each do |expense|
            if expense.date == expenses.last.date
              puts "- #{expense.desc}"
            end
          end
        else
          puts "<red>The are no expenses yet.</red>".colourise
        end
      end
    end
  end
end
