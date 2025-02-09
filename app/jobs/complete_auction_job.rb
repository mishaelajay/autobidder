# frozen_string_literal: true

# Background job responsible for completing auctions.
# Handles the auction completion process including determining winners and notifying users.
class CompleteAuctionJob < ApplicationJob
  queue_as :default

  def perform(auction_id)
    @auction = Auction.find(auction_id)
    return if @auction.completed?
    return unless @auction.ended?

    ActiveRecord::Base.transaction do
      process_auction_completion
    end
  end

  private

  def process_auction_completion
    update_auction_status
    notify_participants
    notify_external_system
  end

  def update_auction_status
    winning_bid = highest_bid
    @auction.update!(
      completed_at: Time.current,
      winning_bid: winning_bid,
      winning_bidder_id: winning_bid&.user_id
    )
  end

  def notify_participants
    if @auction.winning_bid.present?
      notify_winner
      notify_seller_with_winner
      notify_losing_bidders
    else
      notify_seller_no_winner
    end
  end

  def notify_external_system
    ExternalSystemNotifierJob.perform_later(
      event: 'auction_completed',
      auction_id: @auction.id,
      winner_id: @auction.winning_bidder_id,
      winning_amount: @auction.winning_bid&.amount,
      completed_at: @auction.completed_at
    )
  end

  def notify_winner
    AuctionMailer.winner_notification(@auction.winning_bidder, @auction).deliver_later
  end

  def notify_seller_with_winner
    AuctionMailer.seller_auction_completed(@auction.seller, @auction, @auction.winning_bid).deliver_later
  end

  def notify_seller_no_winner
    AuctionMailer.seller_auction_no_winner(@auction.seller, @auction).deliver_later
  end

  def notify_losing_bidders
    losing_bidders.each do |bidder|
      AuctionMailer.auction_lost_notification(@auction, bidder).deliver_later
    end
  end

  def highest_bid
    @highest_bid ||= @auction.bids.order(amount: :desc).first
  end

  def losing_bidders
    @auction.bidders.where.not(id: @auction.winning_bidder_id).distinct
  end
end
