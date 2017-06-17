require 'expenses/expense'

# class BlankConverter < Expenses::Converter
#   def convert(*args)
#     raise ConversionError.new(error)
#   end
# end

describe Expenses::Expense do
  let(:data) do
    { date: '2017-06-16',
      type: 'essential',
      desc: '10 kg worth of rice',
      total: 12000, # In cents.
      currency: 'CZK',
      location: 'PT'}
  end

  describe '.deserialise(data)' do
    it "deserialises valid data and instantiates a new expense" do
      expect(described_class.deserialise(data)).to be_kind_of(described_class)
    end
  end

  context 'offline' do
    let(:described_class) do
      Class.new(Expenses::Expense) do
        def convert_currency(*args)
          # Do not convert anything.
        end
      end
    end

    subject do
      described_class.deserialise(data)
    end

    describe '#serialise' do
      it "serialises ..............." do
        expect(subject.serialise).to eql(data.dup.tap { |data|
          data[:date] = Date.parse(data[:date])
        })
      end
    end
  end
end
