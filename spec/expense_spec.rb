# frozen_string_literal: true

require 'expenses/models/expense'

describe Expenses::Expense do
  let(:data) do
    { 'date'     => '2017-06-16',
      'type'     => 'essential',
      'desc'     => '10 kg worth of rice',
      'total'    => 12000, # In cents.
      'currency' => 'CZK',
      'location' => 'PT'}
  end

  describe '.deserialise(data)' do
    it "deserialises valid data and instantiates a new expense" do
      expect(described_class.deserialise(data)).to be_kind_of(described_class)
    end

    it "raises an error if the date is missing" do
      data.delete('date')

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, /missing: \[:date\]/)
    end

    it "raises an error if the desc is missing" do
      data.delete('desc')

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, /missing: \[:desc\]/)
    end

    it "raises an error if the type is missing" do
      data.delete('type')

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, /missing: \[:type\]/)
    end

    it "raises an error if the total is missing" do
      data.delete('total')

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, /missing: \[:total\]/)
    end

    it "raises an error if the currency is missing" do
      data.delete('currency')

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, /missing: \[:currency\]/)
    end

    it "raises an error if the location is missing" do
      data.delete('location')

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, /missing: \[:location\]/)
    end

    it "raises an error if there are unexpected keys" do
      data.merge!('something_unexpected' => :yes)

      expect { described_class.deserialise(data) }.to raise_error(
        ArgumentError, 'Unexpected key(s): [:something_unexpected]')
    end

    it "raises an error if the provided date is not a date" do
      expect { described_class.deserialise(
        data.tap { |data| data['date'] = '' })
      }.to raise_error(ArgumentError, 'invalid date')

      expect { described_class.deserialise(
        data.tap { |data| data['date'] = false })
      }.to raise_error(TypeError, 'no implicit conversion of false into String')
    end
  end

  describe '.new' do
    let(:data) do
      { date: Date.parse('2017-06-16'),
        type: 'essential',
        desc: '10 kg worth of rice',
        total: 12000,
        currency: 'CZK',
        location: 'PT' }
    end

    subject do
      described_class.deserialise(data)
    end

    it "raises an error if the provided date is not a Date instance" do
      expect { described_class.new(
        data.tap { |data| data[:date] = '2017-06-16' })
      }.to raise_error(TypeError, 'Date has to be an instance of Date.')
    end

    it "raises an error if the provided type is not not one of the supported values" do
      expect { described_class.new(
        data.tap { |data| data[:type] = 'unknown_type' })
      }.to raise_error(ArgumentError, 'Unknown type: unknown_type.')
    end

    it "raises an error if the desc is not a string" do
      expect { described_class.new(
        data.tap { |data| data[:desc] = nil })
      }.to raise_error(TypeError, 'Description has to be a string.')
    end

    it "raises an error if the total is not a round number" do
      expect { described_class.new(
        data.tap { |data| data[:total] = 10.50 })
      }.to raise_error(TypeError, 'Amount has to be a round number.')
    end

    it "raises an error if the tip is not a round number" do
      expect { described_class.new(
        data.tap { |data| data[:tip] = 10.50 })
      }.to raise_error(TypeError, 'Amount has to be a round number.')
    end

    it "raises an error if the currency is not a currency code" do
      expect { described_class.new(
        data.tap { |data| data[:currency] = 'Koruna ceska' })
      }.to raise_error(ArgumentError, 'Currency has to be a three-number code such as CZK.')
    end

    it "raises no error if a note is provided" do
      expect { described_class.new(
        data.tap { |data| data[:note] = 'It was well worth it!' })
      }.not_to raise_error
    end

    it "raises an error if the tag is not a valid tag" do
      expect { described_class.new(
        data.tap { |data| data[:tag] = 'word' })
      }.to raise_error(ArgumentError, 'Tag has to be a #word_or_two.')

      expect { described_class.new(
        data.tap { |data| data[:tag] = '#two-words' })
      }.to raise_error(ArgumentError, 'Tag has to be a #word_or_two.')

      expect { described_class.new(
        data.tap { |data| data[:tag] = '#two_words' })
      }.not_to raise_error
    end

    it "raises an error if the USD total is not a round number" do
      expect { described_class.new(
        data.tap { |data| data[:total_usd] = 10.20 })
      }.to raise_error(TypeError, 'Amount has to be a round number.')

      expect { described_class.new(
        data.tap { |data| data[:total_usd] = 1020 })
      }.not_to raise_error
    end

    it "sets the USD total to the overall total if the currency is USD" do
      instance = described_class.new(data.tap { |data| data[:currency] = 'USD' })
      expect(instance.total_usd).to eql(data[:total])
    end

    it "tries to convert the total to USD if the currency is not USD" do
      klass = Class.new(described_class) do
        def convert_currency(*args)
          :conversion_in_progress
        end
      end

      instance = klass.new(data)
      expect(instance.total_usd).to eql(:conversion_in_progress)
    end

    it "raises an error if the EUR total is not a round number" do
      expect { described_class.new(
        data.tap { |data| data[:total_eur] = 10.20 })
      }.to raise_error(TypeError, 'Amount has to be a round number.')

      expect { described_class.new(
        data.tap { |data| data[:total_eur] = 1020 })
      }.not_to raise_error
    end

    it "sets the EUR total to the overall total if the currency is EUR" do
      instance = described_class.new(data.merge(currency: 'EUR'))
      expect(instance.total_eur).to eql(data[:total])
    end

    it "tries to convert the total to EUR if the currency is not EUR" do
      klass = Class.new(described_class) do
        def convert_currency(*args)
          :conversion_in_progress
        end
      end

      instance = klass.new(data)
      expect(instance.total_eur).to eql(:conversion_in_progress)
    end
  end

  describe '#serialise' do
    let(:described_class) do
      Class.new(Expenses::Expense) do
        def convert_currency(*args)
          # Let's pretend we're offline.
        end
      end
    end

    subject do
      described_class.deserialise(data)
    end

    it "serialises the data" do
      expect(subject.serialise).to eql({
        date: Date.parse(data['date']),
        type: 'essential',
        desc: '10 kg worth of rice',
        total: 12000,
        currency: 'CZK',
        location: 'PT'
      })
    end

    it "leaves out every nil, 0 and empty string" do
      subject = described_class.deserialise(data.merge({tip: 0, note: '', tag: nil}))

      expect(subject.serialise).to eql({
        date: Date.parse(data['date']),
        type: 'essential',
        desc: '10 kg worth of rice',
        total: 12000,
        currency: 'CZK',
        location: 'PT'
      })
    end
  end

  describe '#==(anotherExpense)' do
    let(:data) do
      { date: Date.parse('2017-06-16'),
        type: 'essential',
        desc: '10 kg worth of rice',
        total: 12000,
        currency: 'CZK',
        location: 'PT' }
    end

    subject do
      described_class.new(data)
    end

    it "is true if the serialised data is the same" do
      anotherExpense = described_class.new(data)
      expect(subject == anotherExpense).to be(true)
    end

    it "is false if the serialised data is different" do
      anotherExpense = described_class.new(data.merge(location: 'Barcelona'))
      expect(subject == anotherExpense).to be(false)
    end
  end
end
