describe 'GET /api/v1/user/all', { type: :request } do
  let(:request!) do
    sellers
    get all_api_v1_user_path, params: params, headers: headers
  end
  let(:sellers) { create_list(:user, 2, :seller) }
  let(:params) { {} }
  let(:user) { create(:user, :buyer, deposit_amount: 50) }

  context 'when being signed in' do
    let(:headers) { auth_headers }

    include_examples 'have http status', :ok

    it 'lists every user' do
      expect(json.size).to eq(3)
    end

    it 'shows only the public profile fields' do
      expect(json.first.keys)
        .to match_array(%i[id first_name last_name email locale role created_at updated_at])
    end

    it 'reports the total in the pagination headers' do
      expect(response.headers['Total-Count']).to eq('3')
    end

    context 'with a page size' do
      let(:params) { { items: 2, page: 2 } }

      it 'returns that page' do
        expect(json.size).to eq(1)
      end
    end
  end

  context 'when not being signed in' do
    it_behaves_like 'an authenticated endpoint'
  end
end
