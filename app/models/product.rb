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
class Product < ApplicationRecord
  # The DB column is `available_count`; the HTML/JSON views and several specs
  # refer to it as `available_amount`. Alias so both names work.
  alias_attribute :available_amount, :available_count

  belongs_to :seller, class_name: 'User', optional: true

  validates :name, presence: true
  validates :price,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :available_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def sold_out?
    available_count.to_i.zero?
  end

  # Atomically removes `quantity` units from stock.
  #
  # The decrement is performed as a single conditional UPDATE so two concurrent
  # buyers cannot both read the same `available_count` and drive it negative.
  # Returns true when the stock was actually decremented, false when the
  # quantity is invalid or there is not enough stock left.
  def decrement_stock!(quantity)
    quantity = quantity.to_i
    return false unless quantity.positive?

    updated_rows = self.class
                       .where(id: id)
                       .where('available_count >= ?', quantity)
                       # Deliberately `update_all`: the point is a single
                       # conditional UPDATE that the database evaluates, not a
                       # read-modify-write through the model layer.
                       .update_all( # rubocop:disable Rails/SkipsModelValidations
                         ['available_count = available_count - ?, updated_at = ?',
                          quantity, Time.current]
                       )
    return false if updated_rows.zero?

    reload
    true
  end
end
