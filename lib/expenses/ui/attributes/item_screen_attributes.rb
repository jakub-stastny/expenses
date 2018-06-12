# frozen_string_literal: true

require 'expenses/ui/attributes/screen_attribute'
require 'expenses/ui/attributes/common_attributes'

module Expenses
  module ItemScreenAttributes
    ALL ||= [
      InspectScreenAttribute.new(:desc, {
        editable: true
      }),
      InspectScreenAttribute.new(:quantity, {
        editable: true
      }),
      InspectScreenAttribute.new(:unit, {
        editable: true
      }),
      InspectScreenAttribute.new(:total, {
        editable: true
      }),
      CommonAttributes.note,
      CommonAttributes.tag,
      CommonAttributes.vale_la_pena,
      InspectScreenAttribute.new(:count, {
        editable: true,
        cyclable: true,
        global_cyclable_command: 'c'
        # commander.command('c') do |commander_window|
        #   item.count ||= 1
        #   item.count += 1
        # end
        #
        # commander.command('C') do |commander_window|
        #   item.count ||= 1
        #   if item.count == 2 || item.count == 1
        #     item.count = nil
        #   else
        #     item.count -= 1
        #   end
        # end
      })
    ]
  end
end
