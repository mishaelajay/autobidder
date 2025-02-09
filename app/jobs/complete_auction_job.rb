class CompleteAuctionJob < ApplicationJob
  queue_as :default

  def perform(auction_id)
    auction = Auction.find(auction_id)
    return if auction.completed? || !auction.ended?

    ActiveRecord::Base.transaction do
      # Find the winning bid (highest amount)
      winning_bid = auction.bids
        .includes(:user)
        .order(amount: :desc)
        .first

      # Update auction status and winner
      auction.update!(
        completed_at: Time.current,
        winning_bid_id: winning_bid&.id
      )

      if winning_bid
        # Notify winner
        AuctionMailer.winner_notification(winning_bid.user, auction)
          .deliver_later

        # Notify seller
        AuctionMailer.seller_auction_completed(auction.seller, auction, winning_bid)
          .deliver_later

        # Notify external system about auction completion
        notify_external_system(auction, winning_bid)
      else
        # Notify seller about no winner
        AuctionMailer.seller_auction_no_winner(auction.seller, auction)
          .deliver_later

        # Notify external system about auction with no winner
        notify_external_system(auction, nil)
      end
    end
  end

  private

  def notify_external_system(auction, winning_bid)
    ExternalSystemNotifierJob.perform_later(
      event: 'auction_completed',
      auction_id: auction.id,
      winner_id: winning_bid&.user_id,
      winning_amount: winning_bid&.amount,
      completed_at: auction.completed_at
    )
  end
end 