# frozen_string_literal: true

# Background job responsible for completing auctions.
# Handles the auction completion process including determining winners and notifying users.
class CompleteAuctionJob < ApplicationJob
  queue_as :default

  def perform(auction_id)
    @auction = Auction.find(auction_id)
    return if @auction.completed?

    ActiveRecord::Base.transaction do
      process_auction_completion
    end
  end

  private

  def process_auction_completion
    update_auction_status
    notify_participants if @auction.winning_bid.present?
  end

  def update_auction_status
    @auction.update!(
      completed_at: Time.current,
      winning_bid: highest_bid,
      winning_bidder: highest_bid&.user
    )
  end

  def notify_participants
    notify_winner
    notify_seller
    notify_losing_bidders
  end

  def notify_winner
    BidMailer.winning_bid_notification(@auction.winning_bid).deliver_later
  end

  def notify_seller
    BidMailer.auction_completed_notification(@auction).deliver_later
  end

  def notify_losing_bidders
    losing_bidders.each do |bidder|
      BidMailer.auction_lost_notification(@auction, bidder).deliver_later
    end
  end

  def highest_bid
    @highest_bid ||= @auction.bids.order(amount: :desc).first
  end

  def losing_bidders
    @auction.bidders.where.not(id: @auction.winning_bidder_id).distinct
  end
end
