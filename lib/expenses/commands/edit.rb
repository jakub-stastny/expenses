module Expenses
  module Commands
    class EditCommand < RR::Command
      using RR::ColourExts

      self.help = <<-EOF
        #{self.main_command} <red>edit</red> <bright_black># Edit the expense file in $EDITOR.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args = collection, args
      end

      def run
        system(ENV['EDITOR'] || 'vim', @collection.data_file_path)
      end
    end
  end
end
