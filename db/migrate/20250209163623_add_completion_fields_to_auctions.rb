# frozen_string_literal: true

class AddCompletionFieldsToAuctions < ActiveRecord::Migration[7.0]
  def change
    add_column :auctions, :completed_at, :datetime
    add_reference :auctions, :winning_bid, foreign_key: { to_table: :bids }, null: true
    add_index :auctions, :completed_at
  end
end
