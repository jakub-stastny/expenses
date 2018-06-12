# frozen_string_literal: true

require 'expenses/ui/attributes/screen_attribute'

module Expenses
  module CommonAttributes
    def self.note
      attribute = InspectScreenAttribute.new(:note, editable: true)

      attribute.display_help do |value, is_selected|
        if value
          "Press <red.bold>#{is_selected ? 'e' : 'n'}</red.bold> to edit."
        else
          "Press <red.bold>#{is_selected ? 's' : 'n'}</red.bold> to set."
        end
      end

      attribute
    end

    def self.tag
      attribute = InspectScreenAttribute.new(:tag, editable: true)

      attribute.display_help do |value, is_selected|
        if is_selected
          "Press <red.bold>#</red.bold> to choose one of the existing tags or <red.bold>s</red.bold> to set to a new one."
        else
          "Press <red.bold>#</red.bold> to choose one of the existing tags."
        end
      end

      attribute
    end

    def self.vale_la_pena
      attribute = InspectScreenAttribute.new(:vale_la_pena, cyclable: true, global_cyclable_command: 'v')

      attribute.display_value do |value|
        SerialisableItem::VALE_LA_PENA_LABELS[value] if value
      end

      attribute.cycle_values do |collection, expense|
        SerialisableItem::VALE_LA_PENA_LABELS + [nil]
      end

      attribute
    end
  end
end
