module Expenses
  module Commands
    class EditCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <green>edit</green> <bright_black># Edit the expense file in $EDITOR.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      def run
        system(ENV['EDITOR'] || 'vim', @collection.path.to_s)
      end
    end
  end
end
