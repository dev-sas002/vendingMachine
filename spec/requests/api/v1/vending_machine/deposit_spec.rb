describe 'POST /api/v1/deposit', { type: :request } do
  let(:request!) do
    post api_v1_deposit_path,
         params: { deposit_amount: deposit_amount },
         headers: headers,
         as: :json
  end

  let(:user) { create(:user, :buyer, deposit_amount: 0) }
  let(:deposit_amount) { 50 }
  let(:headers) { auth_headers }

  CoinSet::DEFAULT_DENOMINATIONS.each do |coin|
    context "when depositing an accepted #{coin} coin" do
      let(:deposit_amount) { coin }

      include_examples 'have http status', :ok

      it 'credits the deposit' do
        expect(user.reload.deposit_amount).to eq(coin)
      end
    end
  end

  context 'when depositing twice' do
    it 'accumulates the balance' do
      # The first deposit is issued by the shared `request initializer` context.
      post api_v1_deposit_path, params: { deposit_amount: 20 }, headers: headers, as: :json

      expect(user.reload.deposit_amount).to eq(70)
    end
  end

  context 'when the coin is not accepted' do
    let(:deposit_amount) { 7 }

    include_examples 'have http status', :unprocessable_entity

    it 'reports the invalid amount' do
      expect(json[:error]).to eq('Invalid Amount')
    end

    it 'does not credit the deposit' do
      expect(user.reload.deposit_amount).to eq(0)
    end
  end

  context 'when the amount is missing' do
    let(:deposit_amount) { nil }

    include_examples 'have http status', :unprocessable_entity
  end

  context 'when the amount is negative' do
    let(:deposit_amount) { -50 }

    include_examples 'have http status', :unprocessable_entity

    it 'does not credit the deposit' do
      expect(user.reload.deposit_amount).to eq(0)
    end
  end

  context 'when the user is a seller' do
    let(:user) { create(:user, :seller) }

    include_examples 'have http status', :forbidden
  end

  context 'when not being signed in' do
    it_behaves_like 'an authenticated endpoint'
  end
end
