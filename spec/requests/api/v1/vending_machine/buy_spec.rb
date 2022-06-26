describe 'POST /api/v1/buy', { type: :request } do
  let(:request!) do
    post api_v1_buy_path,
         params: { product_id: product_id, quantity: quantity },
         headers: headers,
         as: :json
  end

  let(:user) { create(:user, :buyer, deposit_amount: 500) }
  let(:product) { create(:product, price: 100, available_count: 5) }
  let(:product_id) { product.id }
  let(:quantity) { 2 }
  let(:headers) { auth_headers }

  context 'when the buyer can afford the order' do
    include_examples 'have http status', :ok

    it 'bills the buyer for the whole order' do
      expect(json[:total_bill]).to eq(200)
    end

    it 'returns the balance left on the machine' do
      expect(json[:remaining_amount]).to eq(300)
    end

    it 'debits the deposit' do
      expect(user.reload.deposit_amount).to eq(300)
    end

    it 'decrements the stock' do
      expect(product.reload.available_count).to eq(3)
    end
  end

  context 'when the order costs exactly the whole deposit' do
    let(:quantity) { 5 }

    include_examples 'have http status', :ok

    it 'leaves the buyer with nothing' do
      expect(user.reload.deposit_amount).to eq(0)
    end

    it 'empties the product' do
      expect(product.reload.available_count).to eq(0)
    end
  end

  context 'when the deposit is insufficient' do
    let(:quantity) { 6 }

    include_examples 'have http status', :unprocessable_entity

    it 'explains why the order was refused' do
      expect(json[:error]).to eq('Order Amount exceeded your current Amount')
    end

    it 'does not debit the deposit' do
      expect(user.reload.deposit_amount).to eq(500)
    end

    it 'does not touch the stock' do
      expect(product.reload.available_count).to eq(5)
    end
  end

  context 'when there is not enough stock' do
    let(:product) { create(:product, price: 10, available_count: 2) }
    let(:quantity) { 3 }

    include_examples 'have http status', :unprocessable_entity

    it 'reports the stock shortfall' do
      expect(json[:error]).to eq('Not enough stock available')
    end

    it 'leaves the stock alone' do
      expect(product.reload.available_count).to eq(2)
    end

    it 'does not charge the buyer' do
      expect(user.reload.deposit_amount).to eq(500)
    end
  end

  context 'when the product is sold out' do
    let(:product) { create(:product, :sold_out, price: 10) }
    let(:quantity) { 1 }

    include_examples 'have http status', :unprocessable_entity

    it 'reports the product as sold out' do
      expect(json[:error]).to eq('Product is sold out')
    end

    it 'does not charge the buyer' do
      expect(user.reload.deposit_amount).to eq(500)
    end
  end

  context 'when the quantity is zero' do
    let(:quantity) { 0 }

    include_examples 'have http status', :unprocessable_entity

    it 'rejects the quantity' do
      expect(json[:error]).to eq('Quantity must be greater than zero')
    end

    it 'does not charge the buyer' do
      expect(user.reload.deposit_amount).to eq(500)
    end
  end

  context 'when the quantity is negative' do
    let(:quantity) { -3 }

    include_examples 'have http status', :unprocessable_entity

    it 'rejects the quantity' do
      expect(json[:error]).to eq('Quantity must be greater than zero')
    end

    it 'does not refund the buyer' do
      expect(user.reload.deposit_amount).to eq(500)
    end

    it 'does not inflate the stock' do
      expect(product.reload.available_count).to eq(5)
    end
  end

  context 'when the product does not exist' do
    let(:product_id) { product.id + 1_000 }

    include_examples 'have http status', :not_found
  end

  context 'when the user is a seller' do
    let(:user) { create(:user, :seller, deposit_amount: 500) }

    include_examples 'have http status', :forbidden
  end

  context 'when not being signed in' do
    it_behaves_like 'an authenticated endpoint'
  end
end
