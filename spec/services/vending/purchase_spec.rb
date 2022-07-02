require 'rails_helper'

describe Vending::Purchase do
  subject(:result) { described_class.call(buyer: buyer, product: product, quantity: quantity) }

  let(:buyer) { create(:user, :buyer, deposit_amount: 500) }
  let(:product) { create(:product, price: 100, available_count: 5) }
  let(:quantity) { 2 }

  context 'when the buyer can afford the order' do
    it 'succeeds' do
      expect(result).to be_success
    end

    it 'bills the whole order' do
      expect(result[:total_amount]).to eq(200)
    end

    it 'reports the balance left on the machine' do
      expect(result[:remaining_amount]).to eq(300)
    end

    it 'debits the balance' do
      result

      expect(buyer.reload.deposit_amount).to eq(300)
    end

    it 'releases the stock' do
      result

      expect(product.reload.available_count).to eq(3)
    end

    it 'breaks the remaining balance into coins' do
      expect(result[:change].coins).to eq(100 => 3)
    end
  end

  context 'when the order costs exactly the whole balance' do
    let(:quantity) { 5 }

    it 'succeeds' do
      expect(result).to be_success
    end

    it 'leaves nothing behind' do
      result

      expect(buyer.reload.deposit_amount).to eq(0)
    end

    it 'empties the product' do
      result

      expect(product.reload.available_count).to eq(0)
    end
  end

  context 'when the balance is too small' do
    let(:quantity) { 6 }

    it 'fails' do
      expect(result).to be_failure
    end

    it 'says the order exceeds the balance' do
      expect(result.error).to eq(described_class::INSUFFICIENT_FUNDS)
    end

    it 'does not debit the balance' do
      result

      expect(buyer.reload.deposit_amount).to eq(500)
    end

    it 'does not touch the stock' do
      result

      expect(product.reload.available_count).to eq(5)
    end
  end

  context 'when there is not enough stock' do
    let(:product) { create(:product, price: 10, available_count: 2) }
    let(:quantity) { 3 }

    it 'reports the shortfall' do
      expect(result.error).to eq(described_class::NOT_ENOUGH_STOCK)
    end

    it 'leaves the stock alone' do
      result

      expect(product.reload.available_count).to eq(2)
    end

    it 'does not charge the buyer' do
      result

      expect(buyer.reload.deposit_amount).to eq(500)
    end
  end

  context 'when the product is sold out' do
    let(:product) { create(:product, :sold_out, price: 10) }
    let(:quantity) { 1 }

    it 'reports the product as sold out' do
      expect(result.error).to eq(described_class::SOLD_OUT)
    end
  end

  [0, -3].each do |bad|
    context "when the quantity is #{bad}" do
      let(:quantity) { bad }

      it 'rejects the quantity' do
        expect(result.error).to eq(described_class::INVALID_QUANTITY)
      end

      it 'does not move any money' do
        result

        expect(buyer.reload.deposit_amount).to eq(500)
      end

      it 'does not move any stock' do
        result

        expect(product.reload.available_count).to eq(5)
      end
    end
  end

  context 'when the debit fails after the stock was released' do
    # Belt and braces: if the balance update ever fails at the last moment the
    # whole unit of work must unwind, stock included.
    before do
      allow(User).to receive(:lock).and_return(User)
      allow(User).to receive(:find).with(buyer.id) do
        User.unscoped.find(buyer.id).tap do |locked|
          allow(locked).to receive(:update_deposit_amount).and_return(false)
        end
      end
    end

    it 'fails' do
      expect(result).to be_failure
    end

    it 'puts the stock back' do
      result

      expect(product.reload.available_count).to eq(5)
    end

    it 'leaves the balance untouched' do
      result

      expect(buyer.reload.deposit_amount).to eq(500)
    end
  end

  describe 'the database refuses to hold impossible money' do
    it 'rejects negative stock even if the application layer asks for it' do
      expect {
        ActiveRecord::Base.transaction(requires_new: true) do
          Product.where(id: product.id).update_all('available_count = -1')
        end
      }.to raise_error(ActiveRecord::StatementInvalid, /products_available_count_non_negative/)
    end

    it 'rejects a negative balance even if the application layer asks for it' do
      expect {
        ActiveRecord::Base.transaction(requires_new: true) do
          User.where(id: buyer.id).update_all('deposit_amount = -1')
        end
      }.to raise_error(ActiveRecord::StatementInvalid, /users_deposit_amount_non_negative/)
    end
  end
end
