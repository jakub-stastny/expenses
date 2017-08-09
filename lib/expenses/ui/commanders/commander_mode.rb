module Expenses
  class CommanderMode
    def run(commander, app, object, screen)
      commander.command('e') do |commander_window|
        result = screen.edit_selected_attribute(app, object)
        @last_run_message = result if result.is_a?(String)
      end
    end
  end
end
