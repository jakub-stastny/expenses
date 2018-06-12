# frozen_string_literal: true

require 'refined-refinements/cli/prompt'

module Expenses
  module Commands
    class RideCommand < RR::Command
      self.help = <<-EOF
        #{self.main_command} <green>ride</green> <bright_black># Log a ride.</bright_black>
      EOF

      def initialize(collection, args)
        @collection, @args, @prompt = collection, args, RR::Prompt.new
      end

      def run
        prompt_date
        prompt_car
        prompt_distance
        prompt_where
        prompt_note

        @collection.items << Ride.new(**@prompt.data)
        @collection.save

        puts "\nRide #{@collection.items.last.serialise.inspect} has been saved."
      end

      private
      def prompt_date
        help = "<green>#{Date.today.iso8601}</green>, anything that <magenta>Data.parse</magenta> parses or <magenta>-1</magenta> for yesterday etc"
        @prompt.prompt(:date, 'Date', help: help) do
          clean_value do |raw_value|
            case raw_value
            when /^$/ then Date.today
            when /^-(\d+)$/ then Date.today - Regexp.last_match(1).to_i
            else Date.parse(raw_value) end
          end

          validate_clean_value do |clean_value|
            clean_value.is_a?(Date)
          end
        end
      end

      def prompt_car
        cars = @collection.rides.map(&:car).uniq

        @prompt.prompt(:car, 'Car', options: cars) do
          clean_value { |raw_value| raw_value }
        end
      end

      def prompt_distance
        @prompt.prompt(:distance, 'Distance') do
          validate_raw_value(/^\d+(\.\d{2})?$/)

          clean_value do |raw_value|
            convert_money_to_cents(raw_value)
          end

          validate_clean_value do |clean_value|
            clean_value.integer?
          end
        end
      end

      def prompt_where
        expenses = @collection.all_expenses
        locations = expenses.map(&:location).uniq.compact
        @prompt.prompt(:where, 'Where', options: locations, default: expenses.last.location) do
          clean_value do |raw_value|
            !raw_value.empty? ? self.self_or_retrieve_by_index(locations, raw_value) : expenses.last.location
          end

          validate_clean_value do |clean_value|
            clean_value && !clean_value.empty?
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
end
