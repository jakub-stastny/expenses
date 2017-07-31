require 'expenses/expense'
require 'expenses/manager'

module Expenses
  module Commander
    def self.add(data_file_path)
      require 'expenses/commands/add'

      manager = Expenses::Manager.new(data_file_path)
      Expenses::Commands::Add.new(manager).run
    end

    def self.last(data_file_path)
      require 'expenses/commands/last'

      manager = Expenses::Manager.new(data_file_path)
      Expenses::Commands::Last.new(manager).run
    end

    def self.report(data_file_path)
      require 'expenses/commands/report'

      manager = Expenses::Manager.new(data_file_path)
      Expenses::Commands::Report.new(manager).run
    end

    def self.review(data_file_path)
      require 'expenses/commands/review'

      manager = Expenses::Manager.new(data_file_path)
      Expenses::Commands::Review.new(manager).run
    end

    def self.console(data_file_path)
      # Console usage:
      # Use manager.save(expenses) to save your modifications.
      manager  = Expenses::Manager.new(data_file_path)
      expenses = manager.parse
      require 'pry'; binding.pry
    end

    def self.edit(data_file_path)
      system(ENV['EDITOR'] || 'vim', data_file_path)
    end
  end
end
