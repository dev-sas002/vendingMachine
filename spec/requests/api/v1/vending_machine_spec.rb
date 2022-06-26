require 'swagger_helper'

RSpec.describe 'api/v1/vending_machine', type: :request do
  let(:buyer) { create(:user, :buyer, deposit_amount: 500) }
  let!(:product) { create(:product, price: 100, available_count: 10) }
  let(:token) { buyer.create_new_auth_token }
  let(:'access-token') { token['access-token'] }
  let(:client) { token['client'] }
  let(:uid) { token['uid'] }

  path '/api/v1/buy' do
    parameter name: :product_id, in: :query, type: :integer, description: 'Product Id'
    parameter name: :quantity, in: :query, type: :integer, description: 'Quantity'
    parameter name: 'access-token', in: :header, type: :string, required: true
    parameter name: 'client', in: :header, type: :string, required: true
    parameter name: 'uid', in: :header, type: :string, required: true

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

        run_test! do
          body = JSON.parse(response.body, symbolize_names: true)
          expect(body[:total_bill]).to eq(100)
          expect(body[:remaining_amount]).to eq(400)
          expect(product.reload.available_count).to eq(9)
        end
      end

      response(422, 'the buyer cannot afford the order') do
        let(:product_id) { product.id }
        let(:quantity) { 100 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(JSON.parse(response.body, symbolize_names: true)[:error])
            .to eq(Vending::Purchase::INSUFFICIENT_FUNDS)
        end
      end
    end
  end

  path '/api/v1/deposit' do
    parameter name: :deposit_amount, in: :query, type: :integer, description: 'Deposit Amount'
    parameter name: 'access-token', in: :header, type: :string, required: true
    parameter name: 'client', in: :header, type: :string, required: true
    parameter name: 'uid', in: :header, type: :string, required: true

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

        run_test! do
          expect(buyer.reload.deposit_amount).to eq(505)
        end
      end

      response(422, 'the machine does not take that coin') do
        let(:deposit_amount) { 7 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          expect(JSON.parse(response.body, symbolize_names: true)[:error])
            .to eq(Vending::Deposit::INVALID_AMOUNT)
        end
      end
    end
  end

  path '/api/v1/reset' do
    parameter name: 'access-token', in: :header, type: :string, required: true
    parameter name: 'client', in: :header, type: :string, required: true
    parameter name: 'uid', in: :header, type: :string, required: true

    post('reset vending_machine') do
      response(200, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          body = JSON.parse(response.body, symbolize_names: true)
          expect(body[:returned_amount]).to eq(500)
          expect(buyer.reload.deposit_amount).to eq(0)
        end
      end
    end
  end
end
