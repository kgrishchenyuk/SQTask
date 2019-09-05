class CreateLots < ActiveRecord::Migration[6.0]
  def change
    create_table :lots do |t|
      t.references :user
      t.references :item
      t.integer :amount
      t.integer :price
      t.boolean :public
    end
  end
end
