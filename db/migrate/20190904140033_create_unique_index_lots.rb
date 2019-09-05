class CreateUniqueIndexLots < ActiveRecord::Migration[6.0]
  def change
    add_index :lots, [:user_id, :item_id], unique: true
  end
end
