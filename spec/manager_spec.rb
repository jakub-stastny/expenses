require 'expenses/manager'

describe Expenses::Manager do
  let(:data_file_path) do
    'spec/data/expenses.json'
  end

  subject do
    described_class.new(data_file_path)
  end

  describe '.new(data_file_path)' do
    it "requires data_file_path" do
      expect(subject.data_file_path).to eql(data_file_path)
    end
  end

  describe '#parse' do
    context "with a valid JSON file" do
      it "returns a list of expenses from the file" do
        expect(subject.parse.first).to be_kind_of(Expenses::Expense)
      end
    end

    context "with an empty file" do
      it "returns an empty array" do
        instance = described_class.new('spec/data/empty-expenses.json')
        expect(instance.parse).to be_empty
      end
    end
  end

  describe '#save(expenses)' do
    let(:temporary_data_file_path) do
      'spec/temporary-expenses-file.json'
    end

    before(:each) do
      File.open(temporary_data_file_path, 'w').close
    end

    after(:each) do
      File.unlink(temporary_data_file_path)
    end

    subject do
      described_class.new(temporary_data_file_path)
    end

    it "saves the expenses into the data_file_path" do
      subject.save(Array.new)
      expect(JSON.parse(File.read(temporary_data_file_path))).to be_empty
    end
  end
end
