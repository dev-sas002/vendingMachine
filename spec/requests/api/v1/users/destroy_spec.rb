describe 'DELETE /api/v1/user' do
  let(:request!) { delete api_v1_user_path, headers: headers, as: :json }

  context 'when being signed in' do
    let(:headers) { auth_headers }

    context 'when the user is a buyer' do
      let(:user) { create(:user, :buyer) }

      include_examples 'have http status', :no_content

      it 'deletes the account' do
        expect(User).not_to exist(user.id)
      end
    end

    context 'when the user is a seller with stock in the machine' do
      let(:user) { create(:user, :seller) }
      let!(:product) { create(:product, seller: user) }
      let(:request!) { nil }

      it 'deletes the account' do
        expect { delete api_v1_user_path, headers: headers, as: :json }
          .to change(User, :count).by(-1)
      end

      it 'takes their products out of the machine' do
        delete api_v1_user_path, headers: headers, as: :json

        expect(Product).not_to exist(product.id)
      end
    end

    context 'when the deleted account tries to sign in again' do
      let(:user) { create(:user, :buyer) }

      it 'is no longer authenticated' do
        get api_v1_user_path, headers: headers, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context 'when not being signed in' do
    it_behaves_like 'an authenticated endpoint'
  end
end
