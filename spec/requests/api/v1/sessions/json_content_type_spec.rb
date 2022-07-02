describe 'POST /api/v1/users/sign_in content negotiation', { type: :request } do
  # `user` is referenced inside `request!` so the record exists before the
  # shared request initializer fires the call.
  let(:user) { create(:user, :buyer, email: 'buyer@example.com', password: 'abcd1234') }
  let(:body) { { user: { email: 'buyer@example.com', password: password } }.to_json }
  let(:password) { 'abcd1234' }

  context 'when the client sends a JSON body but no Accept header' do
    # A JSON body is proof the caller is an API client, so CSRF protection must
    # not reject it. This used to raise InvalidAuthenticityToken and answer 500.
    let(:request!) do
      user
      post '/api/v1/users/sign_in', params: body,
                                    headers: { 'CONTENT_TYPE' => 'application/json' }
    end

    include_examples 'have http status', :ok

    it 'returns an access token' do
      expect(response.headers['access-token']).to be_present
    end
  end

  context 'when the client negotiates JSON properly' do
    let(:request!) do
      user
      post '/api/v1/users/sign_in', params: { user: { email: user.email, password: password } },
                                    as: :json
    end

    include_examples 'have http status', :ok
  end

  context 'when the credentials are wrong' do
    let(:password) { 'not-the-password' }
    let(:request!) do
      user
      post '/api/v1/users/sign_in', params: body,
                                    headers: { 'CONTENT_TYPE' => 'application/json' }
    end

    include_examples 'have http status', :forbidden
  end
end
