# TODO: '*' and '/' expressions in total triggers adding a new item (diesel and the like).

module Expenses
  class Item
    # Unless tag specified explicitly, we'll work with the expense tag instead.
    #
    # Quantity should be an integer at all times. Therefore typically grams and
    #   mililitres would be used rather than kgs and litres.
    #
    # Item.new(desc: "Maślanka naturalna", total: 215, quantity: 1000, unit: 'mililitres', number: 2)
    #   This means we bought 2 boxes of maślanka, 1 litre each.
    def initialize(desc:, total:, note: nil, quantity: nil, unit: nil, number: nil, tag: nil, vale_la_pena: nil)
    end
  end
end
