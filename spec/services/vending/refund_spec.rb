require 'rails_helper'

describe Vending::Refund do
  subject(:result) { described_class.call(buyer: buyer) }

  context 'when the buyer has an exactly payable balance' do
    let(:buyer) { create(:user, :buyer, deposit_amount: 175) }

    it 'succeeds' do
      expect(result).to be_success
    end

    it 'reports what was on the machine' do
      expect(result[:returned_amount]).to eq(175)
    end

    it 'empties the balance' do
      result

      expect(buyer.reload.deposit_amount).to eq(0)
    end

    it 'dispenses the fewest coins' do
      expect(result[:change].coins).to eq(100 => 1, 50 => 1, 20 => 1, 5 => 1)
    end

    it 'leaves nothing over' do
      expect(result[:change]).to be_exact
    end
  end

  context 'when the balance cannot be made up from the coin set' do
    let(:buyer) { create(:user, :buyer, deposit_amount: 103) }

    it 'dispenses what it can' do
      expect(result[:change].total).to eq(100)
    end

    it 'reports the shortfall rather than swallowing it' do
      expect(result[:change].remainder).to eq(3)
    end

    it 'still empties the balance' do
      result

      expect(buyer.reload.deposit_amount).to eq(0)
    end
  end

  context 'when the buyer has nothing on the machine' do
    let(:buyer) { create(:user, :buyer, deposit_amount: 0) }

    it 'succeeds' do
      expect(result).to be_success
    end

    it 'returns nothing' do
      expect(result[:returned_amount]).to eq(0)
    end

    it 'dispenses no coins' do
      expect(result[:change].coins).to be_empty
    end
  end

  context 'when the update fails' do
    let(:buyer) { create(:user, :buyer, deposit_amount: 50) }

    before do
      allow(buyer).to receive(:update).and_return(false)
      buyer.errors.add(:base, 'jammed')
    end

    it 'fails' do
      expect(result).to be_failure
    end

    it 'reports the model errors' do
      expect(result.error).to include('jammed')
    end
  end
end
