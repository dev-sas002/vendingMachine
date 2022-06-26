# The 2026-09-22 audit fixed an inverted funds check and a missing stock check
# that had allowed `products.available_count` to go negative. These constraints
# make that class of bug impossible to persist: the database refuses the write
# no matter what the application layer believes.
#
# Both tables are small in every environment this runs in, so the constraints
# are added and validated in one step; `safety_assured` tells strong_migrations
# that this has been considered rather than overlooked.
class AddNonNegativeMoneyConstraints < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_check_constraint :products,
                           'available_count >= 0',
                           name: 'products_available_count_non_negative'

      add_check_constraint :users,
                           'deposit_amount >= 0',
                           name: 'users_deposit_amount_non_negative'
    end
  end
end
