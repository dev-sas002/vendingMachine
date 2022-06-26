# == Schema Information
#
# Table name: products
#
#  id              :bigint           not null, primary key
#  available_count :integer          default(0)
#  name            :string           not null
#  price           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  seller_id       :bigint           indexed
#
# Indexes
#
#  index_products_on_seller_id  (seller_id)
#
require 'rails_helper'

RSpec.describe Product, type: :model do
  subject(:product) { create(:product, available_count: 5, price: 100) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    specify do
      expect(product).to validate_numericality_of(:price)
        .is_greater_than_or_equal_to(0).only_integer
    end

    specify do
      expect(product).to validate_numericality_of(:available_count)
        .is_greater_than_or_equal_to(0).only_integer
    end

    it 'rejects a negative stock level' do
      product.available_count = -1

      expect(product).not_to be_valid
    end

    it 'rejects a negative price' do
      product.price = -1

      expect(product).not_to be_valid
    end
  end

  describe '#sold_out?' do
    it 'is false while stock remains' do
      expect(product).not_to be_sold_out
    end

    it 'is true at zero stock' do
      expect(create(:product, :sold_out)).to be_sold_out
    end
  end

  describe '#decrement_stock!' do
    it 'removes the requested quantity' do
      expect(product.decrement_stock!(2)).to be(true)
      expect(product.available_count).to eq(3)
    end

    it 'allows draining the stock to exactly zero' do
      expect(product.decrement_stock!(5)).to be(true)
      expect(product.available_count).to eq(0)
    end

    it 'refuses to oversell and leaves the stock untouched' do
      expect(product.decrement_stock!(6)).to be(false)
      expect(product.reload.available_count).to eq(5)
    end

    it 'refuses to sell a sold out product' do
      sold_out = create(:product, :sold_out)

      expect(sold_out.decrement_stock!(1)).to be(false)
      expect(sold_out.reload.available_count).to eq(0)
    end

    it 'rejects a zero quantity' do
      expect(product.decrement_stock!(0)).to be(false)
      expect(product.reload.available_count).to eq(5)
    end

    it 'rejects a negative quantity so stock cannot be inflated' do
      expect(product.decrement_stock!(-3)).to be(false)
      expect(product.reload.available_count).to eq(5)
    end

    it 'coerces a string quantity' do
      expect(product.decrement_stock!('2')).to be(true)
      expect(product.available_count).to eq(3)
    end

    it 'never lets two interleaved decrements go below zero' do
      other = described_class.find(product.id)

      expect(product.decrement_stock!(3)).to be(true)
      # `other` still holds the stale count of 5, but the conditional UPDATE
      # is evaluated against the current row.
      expect(other.decrement_stock!(3)).to be(false)
      expect(product.reload.available_count).to eq(2)
    end
  end

  describe '#available_amount alias' do
    it 'reads through to available_count' do
      expect(product.available_amount).to eq(product.available_count)
    end

    it 'writes through to available_count' do
      product.available_amount = 8

      expect(product.available_count).to eq(8)
    end
  end
end
