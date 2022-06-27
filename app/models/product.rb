# == Schema Information
#
# Table name: products
#
#  id              :bigint           not null, primary key
#  available_count :integer          default(0)
#  name            :string           not null
#  price           :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  seller_id       :bigint           not null, indexed
#
# Indexes
#
#  index_products_on_seller_id  (seller_id)
#
class Product < ApplicationRecord
  # Specs and JSON views refer to `available_amount` while the DB column is
  # `available_count`. Alias the attribute to keep both API contracts working.
  alias_attribute :available_amount, :available_count

  belongs_to :seller, class_name: 'User', foreign_key: :seller_id, optional: true

  def update_product_quantity(quantity)
    # Some specs insert empty strings for `available_amount`, which can
    # type-cast to NULL for `available_count`. Treat NULL as 0.
    current_available = available_count || 0
    update(available_count: current_available - quantity)
  end
end
