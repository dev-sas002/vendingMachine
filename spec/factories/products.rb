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
FactoryBot.define do
  factory :product do
    name { 'MyProduct' }
    available_count { 10 }
    price { 100 }
    association :seller, factory: %i[user seller]

    trait :sold_out do
      available_count { 0 }
    end
  end
end
