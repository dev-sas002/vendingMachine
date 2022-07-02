describe 'POST /api/v1/reset', { type: :request } do
  let(:request!) { post api_v1_reset_path, headers: headers, as: :json }

  let(:user) { create(:user, :buyer, deposit_amount: 175) }
  let(:headers) { auth_headers }

  context 'when the buyer has a balance' do
    include_examples 'have http status', :ok

    it 'reports how much was handed back' do
      expect(json[:returned_amount]).to eq(175)
    end

    it 'empties the deposit' do
      expect(user.reload.deposit_amount).to eq(0)
    end
  end

  context 'when the buyer has no balance' do
    let(:user) { create(:user, :buyer, deposit_amount: 0) }

    include_examples 'have http status', :ok

    it 'returns nothing' do
      expect(json[:returned_amount]).to eq(0)
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
