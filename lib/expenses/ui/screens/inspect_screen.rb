require 'refined-refinements/colours'
require 'expenses/ui/screens/screen_attribute'

module Expenses
  class InspectScreen
    using RR::ColourExts

    def attributes
      Array.new
    end

    def run(commander, commander_window, label, selected_attribute = nil, last_run_message = nil, &block)
      @selected_attribute = selected_attribute || self.attributes.first
      data = @data = block.call

      lines = self.get_lines(data)
      text = "<blue.bold>#{label}:</blue.bold>\n#{lines.join("\n")}\n"
      commander_window.write(text)

      self.set_status_line(commander, commander_window, last_run_message)
    end

    def edit_selected_attribute(app, object)
      if @selected_attribute.editable?
        @selected_attribute.edit(app, object)
      else
        "Attribute #{@selected_attribute.name} isn't directly editable."
      end
    end

    def cycle_values_of_selected_attribute(app, object, char)
      if @selected_attribute.cyclable?
        @selected_attribute.cycle(app, object, char)
      else
        "Values #{@selected_attribute.name} can't be cycled."
      end
    end

    def get_lines(data)
      items = data.reduce(Array.new) do |buffer, (key, value)|
        attribute = self.attributes.find { |attribute| attribute.name == key }

        if attribute
          buffer << attribute.render(key, value, attribute == @selected_attribute)
        else
          buffer
        end
      end

      longest_item = items.map { |items| RR::TemplateString.new(items.first) }.max_by(&:length)

      if (@longest_item_length || 0) < longest_item.length
        @longest_item_length = longest_item.length + 7 # Give it some give, so it doesn't get updated too much.
      end

      items.map do |(data, help)|
        data_length = RR::TemplateString.new(data).length
        spaces = ' ' * (@longest_item_length - data_length)
        "  #{data}#{spaces} # #{help}"
      end
    end

    def set_next_attribute
      index = self.attributes.index(@selected_attribute)
      if self.attributes[index + 1]
        @selected_attribute = self.attributes[index + 1]
      end
    end

    def set_previous_attribute
      index = self.attributes.index(@selected_attribute)
      if index > 0
        @selected_attribute = self.attributes[index - 1]
      end
    end

    def set_status_line(commander, commander_window, last_run_message)
      original_y = commander_window.cury
      commander_window.setpos(Curses.lines - 1, 0)
      commander_window.write(last_run_message ? "<on_red>#{last_run_message}</on_red> #{commander.help}" : commander.help)
      commander_window.setpos(original_y, 0)
    end
  end
end
