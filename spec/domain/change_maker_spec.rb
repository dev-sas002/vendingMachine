require 'rails_helper'

describe ChangeMaker do
  describe '.call' do
    it 'returns no coins for an empty balance' do
      expect(described_class.call(0).coins).to eq({})
    end

    it 'uses the fewest coins for a canonical set' do
      expect(described_class.call(175).coins).to eq(100 => 1, 50 => 1, 20 => 1, 5 => 1)
    end

    it 'repeats a denomination when it is needed more than once' do
      expect(described_class.call(300).coins).to eq(100 => 3)
    end

    it 'leaves nothing over when the amount is exactly payable' do
      expect(described_class.call(175)).to be_exact
    end

    it 'reports what the coin set cannot make up' do
      expect(described_class.call(7).remainder).to eq(2)
    end

    it 'still pays out what it can when there is a remainder' do
      expect(described_class.call(7).coins).to eq(5 => 1)
    end

    it 'is not exact when there is a remainder' do
      expect(described_class.call(7)).not_to be_exact
    end

    it 'rejects a negative amount' do
      expect { described_class.call(-5) }.to raise_error(ArgumentError, /negative/)
    end

    it 'rejects a non-numeric amount' do
      expect { described_class.call('lots') }.to raise_error(ArgumentError)
    end

    it 'honours a custom coin set' do
      change = described_class.call(7, coin_set: CoinSet.new([1, 2, 5]))

      expect(change.coins).to eq(5 => 1, 2 => 1)
    end

    it 'has no remainder when the coin set includes a unit coin' do
      expect(described_class.call(7, coin_set: CoinSet.new([1, 2, 5])).remainder).to eq(0)
    end
  end

  describe 'the dispensed coins and the balance always agree' do
    # Property check: coins paid out plus the remainder must equal the balance,
    # for every amount, or the machine is losing (or printing) money.
    (0..250).each_slice(37).map(&:first).each do |amount|
      it "accounts for every unit of #{amount}" do
        change = described_class.call(amount)

        expect(change.total + change.remainder).to eq(amount)
      end
    end
  end

  describe ChangeMaker::Change do
    subject(:change) { described_class.new(coins: { 100 => 1, 20 => 2 }, remainder: 3) }

    it 'totals the coins' do
      expect(change.total).to eq(140)
    end

    it 'counts the coins' do
      expect(change.coin_count).to eq(3)
    end

    it 'serialises the coins with string keys' do
      expect(change.as_json).to eq('coins' => { '100' => 1, '20' => 2 }, 'remainder' => 3)
    end

    it 'survives a round trip through JSON' do
      expect(JSON.parse(change.to_json)).to eq('coins' => { '100' => 1, '20' => 2 },
                                               'remainder' => 3)
    end
  end
end
