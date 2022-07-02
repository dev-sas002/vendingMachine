require 'rails_helper'

describe ProductAttributes do
  def params_for(hash)
    ActionController::Parameters.new(hash)
  end

  it 'reads top-level fields' do
    expect(described_class.from(params_for(name: 'Coke', price: 50)).to_h)
      .to eq('name' => 'Coke', 'price' => 50)
  end

  it 'reads fields nested under product' do
    expect(described_class.from(params_for(product: { name: 'Coke' })).to_h)
      .to eq('name' => 'Coke')
  end

  it 'prefers the nested shape when both are present' do
    params = params_for(name: 'Top', product: { name: 'Nested' })

    expect(described_class.from(params).to_h).to eq('name' => 'Nested')
  end

  it 'treats amount as the price' do
    expect(described_class.from(params_for(amount: 150)).to_h).to eq('price' => 150)
  end

  it 'drops the amount alias once it has been mapped' do
    expect(described_class.from(params_for(amount: 150)).to_h).not_to have_key('amount')
  end

  it 'keeps an explicit price when no alias is sent' do
    expect(described_class.from(params_for(price: 10)).to_h).to eq('price' => 10)
  end

  it 'ignores anything not on the permit list' do
    expect(described_class.from(params_for(name: 'Coke', id: 9, admin: true)).to_h)
      .to eq('name' => 'Coke')
  end

  it 'returns permitted parameters' do
    expect(described_class.from(params_for(name: 'Coke'))).to be_permitted
  end

  it 'stays permitted after the amount alias is mapped' do
    expect(described_class.from(params_for(amount: 1))).to be_permitted
  end

  it 'accepts the available_amount spelling of the stock column' do
    expect(described_class.from(params_for(available_amount: 3)).to_h)
      .to eq('available_amount' => 3)
  end
end
