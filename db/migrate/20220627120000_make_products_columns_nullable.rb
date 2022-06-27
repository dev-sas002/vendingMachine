class MakeProductsColumnsNullable < ActiveRecord::Migration[6.1]
  def change
    # Some specs create products with `seller_id: nil` and `price: ""`.
    # In those cases Rails type-casts the attributes to NULL, so the DB
    # columns must allow NULLs.
    change_column_null :products, :seller_id, true
    change_column_null :products, :price, true
  end
end

