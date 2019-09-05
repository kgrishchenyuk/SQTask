class CreateUniqueIndexInventories < ActiveRecord::Migration[6.0]
  def change
    add_index :inventories, [:user_id, :item_id], unique: true
  end
end
