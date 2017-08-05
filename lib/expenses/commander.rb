require 'expenses/models/expense'
require 'expenses/collection'
require 'refined-refinements/cli/commander'

# <red.bold>Expenses</red.bold>
#
# Command-line utility for keeping track of expenses in multiple currencies.
#
# Original currency is always saved alongside the EUR and USD equivalent <underline>at the time</underline>.
# This way we can report in either EUR or USD without having to look for old conversion
# rates and hence without the need for internet connection for doing reports.
#
# <green.bold>Options</green.bold>
#
# <%= HELP %>
#
# <green.bold>Environment variables</green.bold>
#
# <yellow>EXPENSE_DATA_FILE_PATH</yellow> defaults to <green>~/Dropbox/Data/Data/Expenses/#{Time.now.year}.json</green>

module Expenses
  class Commander < RR::Commander
    def help_template
      super('Expenses')
    end

    def run(command_name, args)
      command_class = self.class.commands[command_name]
      collection = Expenses::Collection.new("#{Time.now.year}.json")
      command = command_class.new(collection, args)
      command.run
    end

    require 'expenses/commands/add'
    self.command(:+, Commands::AddCommand)

    require 'expenses/commands/withdrawal'
    self.command(:withdrawal, Commands::WithdrawalCommand)

    require 'expenses/commands/income'
    self.command(:income, Commands::IncomeCommand)

    require 'expenses/commands/ride'
    self.command(:ride, Commands::RideCommand)

    require 'expenses/commands/balance'
    self.command(:balance, Commands::BalanceCommand)

    require 'expenses/commands/last'
    self.command(:last, Commands::LastCommand)

    require 'expenses/commands/report'
    self.command(:report, Commands::ReportCommand)

    require 'expenses/commands/review'
    self.command(:review, Commands::ReviewCommand)

    require 'expenses/commands/console'
    self.command(:console, Commands::ConsoleCommand)

    require 'expenses/commands/edit'
    self.command(:edit, Commands::EditCommand)
  end
end
