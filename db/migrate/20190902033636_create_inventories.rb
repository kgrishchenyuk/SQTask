class CreateInventories < ActiveRecord::Migration[6.0]
  def change
    create_table :inventories do |t|
      t.references :user
      t.references :item
      t.integer :amount
    end
  end
end
