require 'expenses/ui/attributes/screen_attribute'
require 'expenses/ui/attributes/common_attributes'

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

    def self.location
      attribute = InspectScreenAttribute.new(:location, cyclable: true, editable: true, global_cyclable_command: 'l')

      attribute.cycle_values do |collection, expense|
        query_engine = QueryEngine.new(collection)
        query_engine.attribute_values_with_counts(collection.expenses, :location).map(&:first)
      end

      attribute.after_update do |collection, expense|
        location = expense.location
        if location.downcase == 'online'
          raise 'TODO: I had this logic somewhere.'
        end

        last_same_location_expense = collection.expenses.reverse.find do |expense|
          expense.location == location
        end

        if last_same_location_expense
          expense.currency = last_same_location_expense.currency
        end
      end

      attribute
    end

    def self.payment_method
      attribute = InspectScreenAttribute.new(:payment_method, cyclable: true, editable: true, global_cyclable_command: 'p')

      attribute.cycle_values do |collection, expense|
        query_engine = QueryEngine.new(collection)
        query_engine.attribute_values_with_counts(collection.expenses, :payment_method).map(&:first)
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
      self.payment_method,
      InspectScreenAttribute.new(:tip, {
        editable: true,
        help: "Press <red.bold>t</red.bold> to edit."
      }),
      CommonAttributes.note,
      CommonAttributes.tag,
      CommonAttributes.vale_la_pena
    ]
  end
end
