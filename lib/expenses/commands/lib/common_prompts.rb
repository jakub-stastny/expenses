require 'refined-refinements/colours'

module Expenses
  module CommonPrompts
    using RR::ColourExts

    def prompt_date
      help = "<green>#{Date.today.iso8601}</green>, anything that <magenta>Data.parse</magenta> parses or <magenta>-1</magenta> for yesterday etc"
      @prompt.prompt(:date, 'Date', help: help) do
        clean_value do |raw_value|
          case raw_value
          when /^$/ then Date.today
          when /^-(\d+)$/ then Date.today - $1.to_i
          else Date.parse(raw_value) end
        end

        validate_clean_value do |clean_value|
          clean_value.is_a?(Date)
        end
      end
    end

    def prompt_desc
      @prompt.prompt(:desc, 'Description') do
        clean_value { |raw_value| raw_value }

        validate_clean_value do |clean_value|
          clean_value && ! clean_value.empty?
        end
      end
    end

    # prompt_money(:tip, 'Tip', allow_empty: true)
    def prompt_money(key, prompt, options = Hash.new)
      @prompt.prompt(key, prompt) do
        validate_raw_value(/^\d+(\.\d{2})?$/, options)

        clean_value do |raw_value|
          convert_money_to_cents(raw_value)
        end

        validate_clean_value do |clean_value|
          clean_value.integer? || clean_value.nil?
        end
      end
    end

    # "10" or "10.30".
    # "34.50 - 3.20"
    # "34.50 - 34"
    # "3.40 * 2" # but not the other way round, otherwise what would be "3 * 2"?
    # "25 + 2.10"

    # TODO: We're well over the head of the prompt library here.
    # It'd be best to reimplement in curses, so we get interactive help as we type.
    def prompt_total
      value_or_expression_regexp = /
        ^
          (?<value_1>\d+(\.\d{2})?)     # First value.
            (\s*(?<operator>[-+*\/])\s* # Operator.
          (?<value_2>\d+(?:\.\d{2})?))? # Second value.
        $
      /x

      help = <<-EOF.gsub(/^\s*/, '')
        <yellow>10</yellow>, <yellow>10.25</yellow> or <green>3.40 * 2</green> for specifying quantity, <green>54.20 + 3.10</green> or <green>54.20 - 3.10</green> for adding tip or <green>54.25 / 49.80</green> for fuel
      EOF

      @prompt.prompt(:total, 'Total', help: help.chomp.colourise) do
        validate_raw_value(value_or_expression_regexp)

        clean_value do |raw_value|
          match = value_or_expression_regexp.match(raw_value)
          if match[:operator]
            value_1 = convert_money_to_cents(match[:value_1])
            value_2 = convert_money_to_cents(match[:value_2])
            case match[:operator]
            when '*'
              # 3.40 * 2 (tickets)
              # 2.10 * 100g (bag of rice)
              # 2.10 * 100g * 2 (2 bags of rice)
              # NOTE: Fuel would be dealt by the / operand.
              if match[:value_2].match(Regexp.quote('.'))
                raise 'xxx'
              end
              operand = match[:value_2].to_i
              r = {total: value_1 * operand, count: operand}
            when '/'
              # 6.80 / 2 (tickets).
              # 57.75 / 48.95
              if match[:value_2].match(Regexp.quote('.'))
                r = {total: value_1, unit: 'ml', quantity: value_2, tag: '#fuel'}
              else
                r = {total: value_1, count: match[:value_2].to_i}
              end
            when '+' # 32.90 + 3.10
              r = {total: value_1 + value_2, tip: [value_1, value_2].min}
            when '-' # 32.90 - 3.10
              raise 'x' if value_2 > value_1
              r = {total: value_1, tip: value_2}
            end
          else
            r = {total: convert_money_to_cents(match[:value_1])}
          end
        end

        # validate_clean_value do |clean_value|
        #   clean_value.values.all? { |value| value.integer? }
        # end
      end
    end

    def prompt_currency(expenses)
      expenses = @collection.all_expenses
      currencies = expenses.map(&:currency).uniq
      @prompt.prompt(:currency, 'Currency code', options: currencies, default: expenses.last.currency) do
        clean_value do |raw_value|
          (not raw_value.empty?) ? self.self_or_retrieve_by_index(currencies, raw_value) : expenses.last.currency
        end

        validate_clean_value do |clean_value|
          clean_value.match(/^[A-Z]{3}$/)
        end
      end
    end

    def prompt_location
      expenses = @collection.all_expenses
      locations = expenses.map(&:location).uniq.compact
      @prompt.prompt(:location, 'Location', options: locations, default: expenses.last.location) do
        clean_value do |raw_value|
          (not raw_value.empty?) ? self.self_or_retrieve_by_index(locations, raw_value) : expenses.last.location
        end

        validate_clean_value do |clean_value|
          clean_value && ! clean_value.empty?
        end
      end
    end

    def prompt_account
      accounts = @collection.balances.map(&:account).uniq

      last_income_item = @collection.income_items.last
      default = last_income_item.account if last_income_item

      @prompt.prompt(:account, 'Account', options: accounts, default: default) do
        clean_value do |raw_value|
          if raw_value.empty?
            default
          else
            self.retrieve_by_index_or_self_if_on_the_list(accounts, raw_value)
          end
        end
      end
    end

    def prompt_note
      @prompt.prompt(:note, 'Note') do
        clean_value { |raw_value| raw_value }
      end
    end
  end
end
