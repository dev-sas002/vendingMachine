require 'rails_helper'

describe CoinSet do
  describe '.default' do
    before { described_class.reset_default! }

    after { described_class.reset_default! }

    it 'uses the built-in denominations when the environment says nothing' do
      expect(described_class.default.denominations).to eq([5, 10, 20, 50, 100])
    end

    it 'reads a custom currency out of the environment' do
      allow(ENV).to receive(:fetch).with(described_class::ENV_KEY, nil).and_return('1, 2, 5')

      expect(described_class.default.denominations).to eq([1, 2, 5])
    end

    it 'falls back to the built-in denominations for a blank value' do
      allow(ENV).to receive(:fetch).with(described_class::ENV_KEY, nil).and_return('   ')

      expect(described_class.default.denominations).to eq(described_class::DEFAULT_DENOMINATIONS)
    end

    it 'memoises the instance' do
      expect(described_class.default).to equal(described_class.default)
    end
  end

  describe '#initialize' do
    it 'sorts and de-duplicates the denominations' do
      expect(described_class.new([20, 5, 20, 10]).denominations).to eq([5, 10, 20])
    end

    it 'rejects an empty set' do
      expect { described_class.new([]) }.to raise_error(ArgumentError, /at least one/)
    end

    it 'rejects non-positive denominations' do
      expect { described_class.new([5, 0]) }.to raise_error(ArgumentError, /positive/)
    end

    it 'rejects values that are not integers' do
      expect { described_class.new(['two']) }.to raise_error(ArgumentError)
    end

    it 'is frozen' do
      expect(described_class.new).to be_frozen
    end
  end

  describe '#descending' do
    it 'lists the denominations largest first' do
      expect(described_class.new([5, 100, 20]).descending).to eq([100, 20, 5])
    end
  end

  describe '#accepts?' do
    subject(:coin_set) { described_class.new([5, 10]) }

    it 'accepts a known denomination' do
      expect(coin_set.accepts?(10)).to be(true)
    end

    it 'rejects an unknown denomination' do
      expect(coin_set.accepts?(7)).to be(false)
    end

    it 'rejects nil' do
      expect(coin_set.accepts?(nil)).to be(false)
    end
  end

  describe '#smallest' do
    it 'returns the smallest denomination' do
      expect(described_class.new([50, 5, 10]).smallest).to eq(5)
    end
  end

  describe '#to_a' do
    it 'returns a mutable copy' do
      coin_set = described_class.new([5, 10])

      expect { coin_set.to_a << 99 }.not_to change(coin_set, :denominations)
    end
  end

  describe 'value equality' do
    it 'is equal to another set with the same denominations' do
      expect(described_class.new([10, 5])).to eq(described_class.new([5, 10]))
    end

    it 'is not equal to a different set' do
      expect(described_class.new([5])).not_to eq(described_class.new([10]))
    end

    it 'is not equal to a non-coin-set' do
      expect(described_class.new([5])).not_to eq([5])
    end

    it 'hashes equal sets alike' do
      expect(described_class.new([5, 10]).hash).to eq(described_class.new([10, 5]).hash)
    end
  end
end
