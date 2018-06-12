# frozen_string_literal: true

require 'expenses/converter'

describe Expenses::Converter do
  describe '.new(base_currency)' do
    it "requires base_currency" do
      expect { described_class.new('EUR') }.not_to raise_error
    end

    it "makes the base_currency accessible" do
      instance = described_class.new('EUR')
      expect(instance.base_currency).to eql('EUR')
    end
  end

  describe '.convert(dest_currency, amount)' do
    it "converts given amount from the base_currency to the dest_currency" do
      instance = described_class.new('EUR')
      expected_value = instance.send(:currency_rates)['CZK'] * 2.50
      expect(instance.convert('CZK', 2.50)).to eql(expected_value)
    end
  end
end
