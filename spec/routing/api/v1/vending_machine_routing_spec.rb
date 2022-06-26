require 'rails_helper'

RSpec.describe Api::V1::VendingMachineController, type: :routing do
  describe 'routing' do
    it 'routes to #buy' do
      expect(post: '/api/v1/buy').to route_to('api/v1/vending_machine#buy', format: :json)
    end

    it 'routes to #deposit' do
      expect(post: '/api/v1/deposit').to route_to('api/v1/vending_machine#deposit', format: :json)
    end

    it 'routes to #reset' do
      expect(post: '/api/v1/reset').to route_to('api/v1/vending_machine#reset', format: :json)
    end
  end
end
