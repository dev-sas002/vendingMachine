require 'rails_helper'

describe Vending::Deposit do
  subject(:result) { described_class.call(buyer: buyer, amount: amount) }

  let(:buyer) { create(:user, :buyer, deposit_amount: 0) }

  CoinSet::DEFAULT_DENOMINATIONS.each do |coin|
    context "with an accepted #{coin} coin" do
      let(:amount) { coin }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'credits the balance' do
        result

        expect(buyer.reload.deposit_amount).to eq(coin)
      end

      it 'reports the new balance' do
        expect(result[:deposit_amount]).to eq(coin)
      end
    end
  end

  context 'with a coin the machine does not take' do
    let(:amount) { 7 }

    it 'fails' do
      expect(result).to be_failure
    end

    it 'names the problem' do
      expect(result.error).to eq(described_class::INVALID_AMOUNT)
    end

    it 'leaves the balance alone' do
      result

      expect(buyer.reload.deposit_amount).to eq(0)
    end
  end

  context 'with a negative amount' do
    let(:amount) { -50 }

    it 'fails' do
      expect(result).to be_failure
    end

    it 'leaves the balance alone' do
      result

      expect(buyer.reload.deposit_amount).to eq(0)
    end
  end

  context 'with a missing amount' do
    let(:amount) { nil }

    it 'fails' do
      expect(result).to be_failure
    end
  end

  context 'with a custom coin set' do
    subject(:result) do
      described_class.call(buyer: buyer, amount: 2, coin_set: CoinSet.new([1, 2, 5]))
    end

    let(:amount) { 2 }

    it 'accepts a coin the default set would reject' do
      expect(result).to be_success
    end
  end

  context 'when the record refuses to save' do
    let(:amount) { 5 }

    before do
      allow(buyer).to receive(:update_deposit_amount).and_return(false)
      buyer.errors.add(:deposit_amount, 'is broken')
    end

    it 'fails' do
      expect(result).to be_failure
    end

    it 'reports the model errors as a list' do
      expect(result.error).to include('Deposit amount is broken')
    end
  end

  it 'accumulates across deposits' do
    described_class.call(buyer: buyer, amount: 50)
    described_class.call(buyer: buyer, amount: 20)

    expect(buyer.reload.deposit_amount).to eq(70)
  end
end
