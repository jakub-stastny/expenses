# frozen_string_literal: true

module Expenses
  class InspectScreenAttribute
    attr_reader :name, :attributes
    def initialize(attribute_name, attributes = Hash.new)
      @name, @attributes = attribute_name, attributes
      @attributes[:cyclable] ||= false
    end

    def display_help(&block)
      @attributes[:help] = block
    end

    def display_value(&block)
      @attributes[:display_value] = block
    end

    def do_cycle(command, &block)
      @attributes[:global_cyclable_command] = command
      @attributes[:cycle] = block
    end

    def render(key, value, is_selected)
      key_tag = @highlighted ? 'yellow.bold' : 'yellow'
      value_tag, value_text = highlight(key, value)
      help = self.help(value, is_selected)
      ["<#{key_tag}>#{key}:</#{key_tag}> <#{value_tag}>#{value_text}</#{value_tag}>", help]
    end

    def help(value, is_selected)
      result = if @attributes[:help] && @attributes[:help].respond_to?(:call)
        @attributes[:help].call(value, is_selected)
      elsif @attributes[:help]
        @attributes[:help]
      elsif @attributes[:help].nil? && self.editable? && !self.cyclable?
        "Press <red.bold>#{value ? 'e' : 's'}</red.bold> to #{value ? 'edit' : 'set'}."
      elsif @attributes[:help].nil? && self.cyclable? && !self.editable?
        "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values."
      elsif @attributes[:help].nil? && self.editable? && self.cyclable?
        "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values or <red.bold>#{value ? 'e' : 's'}</red.bold> to #{value ? 'edit' : 'set'}."
      end

      is_selected ? "<bold>#{result}</bold>" : result
    end

    def globally_cyclable?
      self.cyclable? && self.global_cyclable_command
    end

    def globally_editable?
      self.editable? && self.global_editable_command
    end

    def cyclable?
      @attributes[:cyclable] || @attributes[:cycle]
    end

    def editable?
      @attributes[:editable] || @attributes[:edit]
    end

    def global_cyclable_command
      @attributes[:global_cyclable_command]
    end

    def global_editable_command
      @attributes[:global_editable_command]
    end

    def cycle_values(&block)
      @cycle_values_block = block
    end

    def after_update(&block)
      @after_update_block = block
    end

    def cycle(app, collection, object, char)
      callable = @attributes[:cycle] || Proc.new do |app, object, command|
        values = @cycle_values_block.call(collection, object)
        current_value = object.send(self.name)

        if ('A'..'Z').cover?(char)
          next_index = (values.index(current_value) || 1) - 1
        else
          next_index = (values.index(current_value) || -1) + 1
          next_index = 0 if next_index == values.length
        end

        object.send("#{self.name}=", values[next_index])

        @after_update_block.call(collection, object) if @after_update_block
      end

      callable.call(app, object, char)
    end

    def edit(app, object)
      callable = @attributes[:edit] || Proc.new do |app, object|
        value = app.readline("New value:") do |key|
          if key.key_code == 27 # Quit on Escape.
            @was_escape_quitted = true
            raise QuitError
          end
        end
        object.send("#{self.name}=", value) unless @was_escape_quitted
      end

      callable.call(app, object)
    end

    def highlight!
      @highlighted = true
    end

    def highlight(key, value)
      value = @attributes[:display_value].call(value) if @attributes[:display_value]

      case value
      when Date
        [:magenta, value.strftime('%A %d/%m')]
      when nil
        [:cyan, 'nil']
      when true, false
        [:red, value.to_s]
      when Integer
        if [:total, :tip, :unit_price].include?(key)
          [:red, Utils.format_cents_to_money(value)]
        else
          [:red, value]
        end
      when String
        [:green, "\"#{value}\""]
      when Array
        [:yellow, value.inspect]
      else
        raise value.inspect
      end
    end
  end
end
