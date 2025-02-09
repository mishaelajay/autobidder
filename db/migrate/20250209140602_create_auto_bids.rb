class CreateAutoBids < ActiveRecord::Migration[7.0]
  def change
    create_table :auto_bids do |t|
      t.references :user, null: false, foreign_key: true
      t.references :auction, null: false, foreign_key: true
      t.decimal :maximum_amount, precision: 10, scale: 2, null: false
      t.timestamps
    end
    
    add_index :auto_bids, [:auction_id, :maximum_amount]
    add_index :auto_bids, [:user_id, :auction_id], unique: true
  end
end
