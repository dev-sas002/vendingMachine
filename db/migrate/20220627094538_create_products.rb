class CreateProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.integer :available_count, default: 0
      t.integer :price, null: false
      t.references :seller, null: false

      t.timestamps
    end
  end
end
