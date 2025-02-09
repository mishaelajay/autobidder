# frozen_string_literal: true

# Background job responsible for updating auction statuses.
# Periodically checks and updates the status of active auctions.
class AuctionStatusUpdaterJob < ApplicationJob
  queue_as :default

  def perform
    # Find auctions that have ended but haven't been processed
    Auction.active.where(ends_at: ..Time.current).find_each do |auction|
      # Process the auction end
      process_auction_end(auction)
    end
  end

  private

  def process_auction_end(auction)
    # Determine winner and send notifications
    if auction.winner
      # Notify winner
      AuctionMailer.auction_won_notification(auction.winner, auction).deliver_later
      # Notify seller
      AuctionMailer.auction_ended_with_winner_notification(auction.seller, auction).deliver_later
    else
      # Notify seller about no winner
      AuctionMailer.auction_ended_without_winner_notification(auction.seller, auction).deliver_later
    end
  end
end
