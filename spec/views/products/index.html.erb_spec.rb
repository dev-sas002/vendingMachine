require 'rails_helper'

RSpec.describe 'products/index', type: :view do
  let(:seller) { create(:user, :seller) }

  before do
    assign(:products, [
             create(:product, name: 'Coke', available_amount: 4, price: 120, seller: seller),
             create(:product, name: 'Chips', available_amount: 7, price: 80, seller: seller)
           ])
  end

  it 'renders one row per product' do
    render
    assert_select 'tbody > tr', count: 2
  end

  it 'renders each product name and available amount' do
    render
    assert_select 'tr > td', text: 'Coke', count: 1
    assert_select 'tr > td', text: '4', count: 1
    assert_select 'tr > td', text: 'Chips', count: 1
    assert_select 'tr > td', text: '7', count: 1
  end
end
