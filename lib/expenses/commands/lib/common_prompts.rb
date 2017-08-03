module Expenses
  module CommonPrompts
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
