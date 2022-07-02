require 'rails_helper'

describe ServiceResult do
  describe '.success' do
    subject(:result) { described_class.success(total: 10) }

    it 'is a success' do
      expect(result).to be_success
    end

    it 'is not a failure' do
      expect(result).not_to be_failure
    end

    it 'carries no error' do
      expect(result.error).to be_nil
    end

    it 'exposes the payload by key' do
      expect(result[:total]).to eq(10)
    end
  end

  describe '.failure' do
    subject(:result) { described_class.failure('nope', total: 0) }

    it 'is a failure' do
      expect(result).to be_failure
    end

    it 'is not a success' do
      expect(result).not_to be_success
    end

    it 'carries the error' do
      expect(result.error).to eq('nope')
    end

    it 'still carries a payload' do
      expect(result[:total]).to eq(0)
    end
  end

  it 'is frozen' do
    expect(described_class.success).to be_frozen
  end

  it 'returns nil for an unknown key' do
    expect(described_class.success[:nope]).to be_nil
  end
end
