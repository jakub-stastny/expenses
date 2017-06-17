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
      described_class.currency_rates['EUR'] = {'CZK' => 25.20}
      instance = described_class.new('EUR')
      expect(instance.convert('CZK', 2.50)).to eql(2.50 * 25.20)
    end
  end
end
