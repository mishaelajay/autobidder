# frozen_string_literal: true

# Migration to add winning bidder reference to auctions.
# Adds a direct reference to the winning user for completed auctions.
class AddWinningBidderIdToAuctions < ActiveRecord::Migration[7.1]
  def change
    add_reference :auctions, :winning_bidder, foreign_key: { to_table: :users }, null: true
  end
end
