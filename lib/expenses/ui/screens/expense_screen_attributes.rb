require 'expenses/ui/screens/screen_attribute'

# (edit should really edit, also 'c' should clear.)
# TODO: make on_red work (last_run_message)
module Expenses
  module ExpenseScreenAttributes
    def self.date
      attribute = InspectScreenAttribute.new(:date)

      attribute.display_help do |value, is_selected|
        command = is_selected ? 'c' : 'd'
        "Set to previous/next day by pressing <red.bold>#{command}</red.bold>/<red.bold>#{command.upcase}</red.bold>."
      end

      attribute.do_cycle('d') do |app, expense, command|
        if command == 'd' || command == 'c'
          expense.date -= 1
        else
          unless expense.date == Date.today
            expense.date += 1
          end
        end
      end

      attribute
    end

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
      attribute = InspectScreenAttribute.new(:vale_la_pena, cyclable: true)

      attribute.display_value do |value|
        SerialisableItem::VALE_LA_PENA_LABELS[value] if value
      end

      attribute.cycle_values do |collection, expense|
        SerialisableItem::VALE_LA_PENA_LABELS + [nil]
      end

      attribute.display_help do |value, is_selected|
        command = is_selected ? 'c' : 'v'
        "Press <red.bold>#{command}</red.bold>/<red.bold>#{command.upcase}</red.bold> to cycle between values."
      end

      attribute
    end

    def self.location
      attribute = InspectScreenAttribute.new(:location, cyclable: true, editable: true, global_cyclable_command: 'l')

      attribute.cycle_values do |collection, expense|
        query_engine = QueryEngine.new(collection)
        query_engine.attribute_values_with_counts(collection.expenses, :location).map(&:first)
      end

      attribute.after_update do |collection, expense|
        location = expense.location

        last_same_location_expense = collection.expenses.reverse.find do |expense|
          expense.location == location
        end

        if last_same_location_expense
          expense.currency = last_same_location_expense.currency
        end
      end

      attribute.display_help do |value, is_selected|
        command = is_selected ? 'c' : 'v'
        "Press <red.bold>#{command}</red.bold>/<red.bold>#{command.upcase}</red.bold> to cycle between values."
      end

      attribute
    end

    ALL ||= [
      self.date,
      InspectScreenAttribute.new(:desc, {
        editable: true
      }),
      self.location,
      InspectScreenAttribute.new(:currency, {
        editable: true,
        help: "Press <red.bold>c</red.bold>/<red.bold>C</red.bold> to cycle between values."
      }),
      InspectScreenAttribute.new(:payment_method, {
        editable: true,
        help: "Press <red.bold>p</red.bold>/<red.bold>P</red.bold> to cycle between values."
      }),
      InspectScreenAttribute.new(:tip, {
        editable: true,
        help: "Press <red.bold>t</red.bold> to edit."
      }),
      self.note,
      self.tag,
      self.vale_la_pena
    ]
  end
end
