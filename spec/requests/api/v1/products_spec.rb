require 'swagger_helper'

RSpec.describe 'api/v1/products', type: :request do
  let!(:products) { create_list(:product, 5) }
  path '/api/v1/products' do
    get('list products') do
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post('create product') do
      parameter name: :name, in: :query, type: :string, required: true, description: 'Name of the Product'
      parameter name: :available_count, in: :query, type: :integer, required: true, description: 'Number of quantities'
      parameter name: :seller_id,in: :query, type: :integer, required: true, description: 'Seller Id'
      parameter name: :price, in: :query, type: :integer, required: true, description: 'Price of the product'

      response(200, 'successful') do
        let(:name) { 'CreatedProduct' }
        let(:available_count) { 10 }
        let(:seller_id) { products.first.seller_id }
        let(:price) { 99 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/products/{id}' do
    # You'll want to customize the parameter types...
    parameter name: 'id', in: :path, type: :string, description: 'id'

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
        run_test!
      end
    end

    patch('update product') do
      parameter name: :amount, in: :path, type: :integer, description: 'Product Price'
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
        run_test!
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
        run_test!
      end
    end
  end
end
