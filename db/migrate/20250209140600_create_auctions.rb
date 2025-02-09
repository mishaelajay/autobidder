# frozen_string_literal: true

class CreateAuctions < ActiveRecord::Migration[7.0]
  def change
    create_table :auctions do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :starting_price, precision: 10, scale: 2, null: false
      t.decimal :minimum_selling_price, precision: 10, scale: 2, null: false
      t.datetime :ends_at, null: false
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :auctions, :ends_at
  end
end
