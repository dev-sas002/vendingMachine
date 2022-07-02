require 'rails_helper'

RSpec.describe ProductsController, type: :routing do
  describe 'HTML scaffold routing' do
    it 'routes to #index' do
      expect(get: '/products').to route_to('products#index')
    end

    it 'routes to #show' do
      expect(get: '/products/1').to route_to('products#show', id: '1')
    end

    it 'exposes no HTML new form' do
      expect(get: '/products/new').not_to be_routable
    end

    it 'exposes no HTML edit form' do
      expect(get: '/products/1/edit').not_to be_routable
    end

    it 'exposes no HTML create route' do
      expect(post: '/products').not_to be_routable
    end

    it 'exposes no HTML update route' do
      expect(patch: '/products/1').not_to be_routable
    end

    it 'exposes no HTML destroy route' do
      expect(delete: '/products/1').not_to be_routable
    end
  end
end
