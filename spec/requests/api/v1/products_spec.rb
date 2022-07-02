require 'swagger_helper'

RSpec.describe 'api/v1/products', type: :request do
  let(:seller) { create(:user, :seller) }
  let!(:products) { create_list(:product, 5, seller: seller) }
  let(:token) { seller.create_new_auth_token }
  let(:'access-token') { token['access-token'] }
  let(:client) { token['client'] }
  let(:uid) { token['uid'] }

  path '/api/v1/products' do
    parameter name: 'access-token', in: :header, type: :string, required: true
    parameter name: 'client', in: :header, type: :string, required: true
    parameter name: 'uid', in: :header, type: :string, required: true

    get('list products') do
      parameter name: :page, in: :query, type: :integer, required: false,
                description: 'Page number (default 1)'
      parameter name: :items, in: :query, type: :integer, required: false,
                description: "Page size (default #{Paginatable::DEFAULT_PAGE_SIZE}, " \
                             "maximum #{Paginatable::MAX_PAGE_SIZE})"

      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(JSON.parse(response.body).size).to eq(5)
        end
      end
    end

    post('create product') do
      parameter name: :name, in: :query, type: :string, required: true,
                description: 'Name of the Product'
      parameter name: :available_count, in: :query, type: :integer, required: true,
                description: 'Number of quantities'
      parameter name: :price, in: :query, type: :integer, required: true,
                description: 'Price of the product'

      response(201, 'created') do
        let(:name) { 'CreatedProduct' }
        let(:available_count) { 10 }
        let(:price) { 99 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          body = JSON.parse(response.body, symbolize_names: true)
          expect(body).to include(name: 'CreatedProduct', available_count: 10, price: 99)
          expect(body[:seller_id]).to eq(seller.id)
        end
      end
    end
  end

  path '/api/v1/products/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    parameter name: 'access-token', in: :header, type: :string, required: true
    parameter name: 'client', in: :header, type: :string, required: true
    parameter name: 'uid', in: :header, type: :string, required: true

    get('show product') do
      response(200, 'successful') do
        let(:id) { products.first.id.to_s }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(products.first.id)
        end
      end
    end

    patch('update product') do
      parameter name: :amount, in: :query, type: :integer, description: 'Product Price'

      response(200, 'successful') do
        let(:id) { products.first.id.to_s }
        let(:amount) { 150 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(products.first.reload.price).to eq(150)
        end
      end
    end

    delete('delete product') do
      response(200, 'successful') do
        let(:id) { products.first.id.to_s }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(Product.exists?(products.first.id)).to be(false)
        end
      end
    end
  end
end
