require 'expenses/expense'
require 'expenses/manager'
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
# expense <cyan>add</cyan>, <cyan>a</cyan>, <cyan>+</cyan>  <bright_black># Interactively add a new expense.</bright_black>
# expense <cyan>last</cyan>, <cyan>l</cyan>  <bright_black># Last day spendings.</bright_black>
# expense <cyan>report</cyan>, <cyan>r</cyan>  <bright_black># Report on your spendings.</bright_black>
# expense <cyan>review</cyan>     <bright_black># Review long-term purchases.</bright_black>
# expense <cyan>console</cyan>, <cyan>c</cyan> <bright_black># Launch Ruby console with expense data loaded.</bright_black>
# expense <cyan>edit</cyan>, <cyan>e</cyan>    <bright_black># Edit expense data in $EDITOR.</bright_black>
#
# <green.bold>Environment variables</green.bold>
#
# <yellow>EXPENSE_DATA_FILE_PATH</yellow> defaults to <green>~/Dropbox/Data/Data/Expenses/#{Time.now.year}.json</green>

module Expenses
  class Commander < RR::Commander
    def help_template
      super('Expenses')
    end

    def manager
      Expenses::Manager.new(data_file_path)
    end

    def run(command_name, data_file_path, args)
      command_class = self.class.commands[command_name]
      manager = Expenses::Manager.new(data_file_path)
      command = command_class.new(manager, args)
      command.run
    end

    require 'expenses/commands/add'
    self.command(:add, Commands::AddCommand)

    require 'expenses/commands/withdrawal'
    self.command(:withdrawal, Commands::WithdrawalCommand)

    require 'expenses/commands/last'
    self.command(:last, Commands::LastCommand)

    require 'expenses/commands/report'
    self.command(:report, Commands::ReportCommand)

    require 'expenses/commands/review'
    self.command(:review, Commands::ReviewCommand)

    require 'expenses/commands/console'
    self.command(:console, Commands::ConsoleCommand)

    # def self.console(data_file_path)
    #   # Console usage:
    #   # Use manager.save(expenses) to save your modifications.
    #   manager  = Expenses::Manager.new(data_file_path)
    #   expenses = manager.parse
    #   require 'pry'; binding.pry
    # end

    # def self.edit(data_file_path)
    #   system(ENV['EDITOR'] || 'vim', data_file_path)
    # end
    require 'expenses/commands/edit'
    self.command(:console, Commands::EditCommand)
  end
end
