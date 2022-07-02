require 'rails_helper'

RSpec.describe 'products/show', type: :view do
  let(:seller) { create(:user, :seller) }
  let(:product) do
    create(:product, name: 'Coke', available_amount: 4, price: 120, seller: seller)
  end

  before { assign(:product, product) }

  it 'renders the product attributes' do
    render

    expect(rendered).to include('Coke')
    expect(rendered).to include('4')
    expect(rendered).to include('120')
    expect(rendered).to include(seller.id.to_s)
  end
end
