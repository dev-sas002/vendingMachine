require 'swagger_helper'

RSpec.describe 'api/v1/vending_machine', type: :request do
  let!(:product) { create(:product) }

  path '/api/v1/buy' do
    parameter name: :product_id, in: :query, type: :integer, description: 'Product Amount'
    parameter name: :quantity, in: :query, type: :integer, description: 'Quantity'
    post('buy vending_machine') do
      response(200, 'successful') do
        let(:product_id) { product.id }
        let(:quantity) { 1 }

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

  path '/api/v1/deposit' do
    parameter name: :deposit_amount, in: :query, type: :integer, description: 'Deposit Amount'
    post('deposit vending_machine') do
      response(200, 'successful') do
        let(:deposit_amount) { 5 }

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

  path '/api/v1/reset' do

    post('reset vending_machine') do
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
  end
end
