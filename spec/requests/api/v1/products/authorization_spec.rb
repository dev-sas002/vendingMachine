describe 'api/v1/products authorization', { type: :request } do
  let(:owner) { create(:user, :seller) }
  let(:product) { create(:product, seller: owner, price: 100, available_count: 3) }

  describe 'POST /api/v1/products' do
    let(:request!) do
      post api_v1_products_path,
           params: { name: 'Water', price: 50, available_count: 3 },
           headers: headers,
           as: :json
    end

    context 'when the user is a seller' do
      let(:user) { owner }
      let(:headers) { auth_headers }

      include_examples 'have http status', :created

      it 'assigns the product to the signed in seller' do
        expect(Product.find(json[:id]).seller).to eq(owner)
      end
    end

    context 'when the user is a buyer' do
      let(:user) { create(:user, :buyer) }
      let(:headers) { auth_headers }

      include_examples 'have http status', :forbidden

      it 'creates nothing' do
        expect(Product.where(name: 'Water')).to be_empty
      end
    end

    context 'when the payload is invalid' do
      let(:user) { owner }
      let(:headers) { auth_headers }
      let(:request!) do
        post api_v1_products_path, params: { name: '', price: -1 }, headers: headers, as: :json
      end

      include_examples 'have http status', :unprocessable_entity

      it 'reports the validation failures' do
        expect(json[:errors]).to include("Name can't be blank")
      end
    end

    context 'when not being signed in' do
      it_behaves_like 'an authenticated endpoint'
    end
  end

  describe 'PATCH /api/v1/products/:id' do
    let(:request!) do
      patch api_v1_product_path(product), params: { price: 250 }, headers: headers, as: :json
    end

    context 'when the seller owns the product' do
      let(:user) { owner }
      let(:headers) { auth_headers }

      include_examples 'have http status', :ok

      it 'updates the price' do
        expect(product.reload.price).to eq(250)
      end
    end

    context 'when another seller owns the product' do
      let(:user) { create(:user, :seller) }
      let(:headers) { auth_headers }

      include_examples 'have http status', :forbidden

      it 'leaves the price untouched' do
        expect(product.reload.price).to eq(100)
      end
    end

    context 'when not being signed in' do
      it_behaves_like 'an authenticated endpoint'
    end
  end

  describe 'DELETE /api/v1/products/:id' do
    let(:request!) { delete api_v1_product_path(product), headers: headers, as: :json }

    context 'when the seller owns the product' do
      let(:user) { owner }
      let(:headers) { auth_headers }

      include_examples 'have http status', :ok

      it 'removes the product' do
        expect(Product.exists?(product.id)).to be(false)
      end
    end

    context 'when another seller owns the product' do
      let(:user) { create(:user, :seller) }
      let(:headers) { auth_headers }

      include_examples 'have http status', :forbidden

      it 'keeps the product' do
        expect(Product.exists?(product.id)).to be(true)
      end
    end

    context 'when not being signed in' do
      it_behaves_like 'an authenticated endpoint'
    end
  end

  describe 'GET /api/v1/products' do
    # `product` is referenced inside the request so it exists before the shared
    # `request initializer` context fires the call.
    let(:request!) do
      product
      get api_v1_products_path, headers: headers, as: :json
    end

    context 'when a buyer lists the machine contents' do
      let(:user) { create(:user, :buyer) }
      let(:headers) { auth_headers }

      include_examples 'have http status', :ok

      it 'returns every product regardless of seller' do
        expect(json.pluck(:id)).to include(product.id)
      end
    end

    context 'when not being signed in' do
      it_behaves_like 'an authenticated endpoint'
    end
  end
end
