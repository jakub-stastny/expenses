module Expenses
  class CommanderMode
    def run(app, commander, collection, object, screen)
      make_commands_from_attributes(app, commander, screen, collection, object)
      make_movable_commands(commander, screen)
      make_locally_editable_and_cyclable(app, commander, screen, collection, object)
    end

    def make_locally_editable_and_cyclable(app, commander, screen, collection, object)
      commander.command('e') do |commander_window|
        result = screen.edit_selected_attribute(app, object)
        @last_run_message = result if result.is_a?(String)
      end

      commander.command(['c', 'C']) do |commander_window, char|
        result = screen.cycle_values_of_selected_attribute(@app, collection, object, char)
        @last_run_message = result if result.is_a?(String)
      end
    end

    def make_movable_commands(commander, screen)
      commander.command(['j', 258]) do |commander_window, char|
        @selected_attribute = screen.set_next_attribute
      end

      commander.command(['k', 259]) do |commander_window|
        @selected_attribute = screen.set_previous_attribute
      end
    end

    def make_movable_commands(commander, screen)
      commander.command(['j', 258]) do |commander_window, char|
        @selected_attribute = screen.set_next_attribute
      end

      commander.command(['k', 259]) do |commander_window|
        @selected_attribute = screen.set_previous_attribute
      end
    end

    def make_commands_from_attributes(app, commander, screen, collection, object)
      screen.attributes.each do |attribute|
        if attribute.globally_cyclable?
          command = attribute.global_cyclable_command
          commander.command([command, command.upcase]) do |commander_window, char|
            attribute.cycle(app, collection, object, char)
          end
        elsif attribute.globally_editable?
          command = attribute.global_editable_command
          commander.command([command, command.upcase]) do |commander_window, char|
            attribute.edit(object, char)
          end
        end
      end
    end
  end
end
