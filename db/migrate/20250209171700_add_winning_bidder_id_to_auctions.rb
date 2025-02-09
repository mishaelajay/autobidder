# frozen_string_literal: true

class AddWinningBidderIdToAuctions < ActiveRecord::Migration[7.1]
  def change
    add_reference :auctions, :winning_bidder, foreign_key: { to_table: :users }, null: true
  end
end
