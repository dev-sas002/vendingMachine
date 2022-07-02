describe 'GET /health', { type: :request } do
  let(:request!) { get '/health' }

  context 'when the database is reachable' do
    include_examples 'have http status', :ok

    it 'reports the process as healthy' do
      expect(json[:status]).to eq('ok')
    end

    it 'reports the database as healthy' do
      expect(json[:database]).to eq('ok')
    end

    it 'needs no authentication' do
      expect(response.headers).not_to have_key('access-token')
    end
  end

  context 'when the database is unreachable' do
    # Stubbed inside `request!` so it is in place before the shared request
    # initializer fires the call.
    let(:request!) do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(PG::ConnectionBad)
      get '/health'
    end

    include_examples 'have http status', :service_unavailable

    it 'says which dependency is down' do
      expect(json[:database]).to eq('unreachable')
    end
  end
end
