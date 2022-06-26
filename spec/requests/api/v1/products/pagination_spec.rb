describe 'GET /api/v1/products pagination', { type: :request } do
  let(:user) { create(:user, :buyer) }
  let(:headers) { auth_headers }
  let(:seller) { create(:user, :seller) }

  # Counts the SELECTs a block issues, ignoring the framework's own bookkeeping.
  def count_queries
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      next if payload[:name].in?(%w[SCHEMA TRANSACTION CACHE])
      next unless payload[:sql].start_with?('SELECT')

      queries << payload[:sql]
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe 'the page size is bounded' do
    let!(:products) { create_list(:product, 30, seller: seller) }
    let(:query) { {} }
    let(:request!) do
      products
      get api_v1_products_path, params: query, headers: headers, as: :json
    end

    context 'with no page parameters' do
      include_examples 'have http status', :ok

      it 'never returns an unbounded collection' do
        expect(json.size).to eq(Paginatable::DEFAULT_PAGE_SIZE)
      end

      it 'reports the total count in a header' do
        expect(response.headers['Total-Count']).to eq('30')
      end

      it 'reports the page size in a header' do
        expect(response.headers['Page-Items']).to eq(Paginatable::DEFAULT_PAGE_SIZE.to_s)
      end

      it 'links to the next page' do
        expect(response.headers['Link']).to include('rel="next"')
      end
    end

    context 'with an explicit page' do
      let(:query) { { page: 2 } }

      it 'returns the remainder' do
        expect(json.size).to eq(5)
      end

      it 'does not repeat the first page' do
        expect(json.first[:id]).to eq(Product.order(:id).offset(25).first.id)
      end
    end

    context 'with an explicit page size' do
      let(:query) { { items: 4 } }

      it 'honours it' do
        expect(json.size).to eq(4)
      end
    end

    context 'with an absurd page size' do
      let(:query) { { items: 10_000 } }

      it 'clamps it to the maximum' do
        expect(json.size).to eq(Paginatable::MAX_PAGE_SIZE.clamp(0, 30))
      end
    end

    context 'with a nonsense page size' do
      let(:query) { { items: 'lots' } }

      it 'falls back to the default' do
        expect(json.size).to eq(Paginatable::DEFAULT_PAGE_SIZE)
      end
    end

    context 'with a page past the end' do
      let(:query) { { page: 99 } }

      include_examples 'have http status', :unprocessable_entity
    end
  end

  describe 'the seller block does not cost a query per product' do
    let(:request!) { nil }

    it 'includes the seller in the payload' do
      create(:product, seller: seller)
      get api_v1_products_path, headers: headers, as: :json

      expect(json.first[:seller]).to include(id: seller.id, email: seller.email)
    end

    it 'issues the same number of queries for 5 products and for 25' do
      # Warm the lazily-built buyer and its auth token first, so only the
      # index request itself is measured.
      headers

      create_list(:product, 5, seller: seller)
      few = count_queries { get api_v1_products_path, headers: headers, as: :json }

      create_list(:product, 20, seller: create(:user, :seller))
      many = count_queries { get api_v1_products_path, headers: headers, as: :json }

      expect(many.size).to eq(few.size)
    end

    # Two token lookups from devise_token_auth, then pagy's COUNT, the page of
    # products and a single preload of their sellers. Five, whatever the page
    # holds. Raise this number only if you meant to.
    it 'keeps a full page of 25 products at five queries' do
      headers
      create_list(:product, 25, seller: seller)

      queries = count_queries { get api_v1_products_path, headers: headers, as: :json }

      expect(queries.size).to eq(5)
    end
  end
end
