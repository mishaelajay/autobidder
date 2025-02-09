# frozen_string_literal: true

class CreateBids < ActiveRecord::Migration[7.0]
  def change
    create_table :bids do |t|
      t.references :user, null: false, foreign_key: true
      t.references :auction, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.timestamps
    end

    add_index :bids, %i[auction_id amount]
  end
end
