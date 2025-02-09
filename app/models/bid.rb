class Bid < ApplicationRecord
  belongs_to :user
  belongs_to :auction, touch: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :auction_must_be_active
  validate :amount_must_be_minimum_next_bid
  validate :cannot_bid_on_own_auction
  
  after_commit :schedule_auto_bids_processing, on: :create
  after_commit :notify_outbid_users, on: :create
  after_create_commit :broadcast_bid

  private

  def auction_must_be_active
    if auction.ended?
      errors.add(:base, "Cannot bid on ended auction")
    end
  end

  def amount_must_be_minimum_next_bid
    minimum_required = auction.minimum_next_bid
    if amount < minimum_required
      errors.add(:amount, "must be at least #{minimum_required}")
    end
  end

  def cannot_bid_on_own_auction
    if user_id == auction.seller_id
      errors.add(:base, "Cannot bid on your own auction")
    end
  end

  def schedule_auto_bids_processing
    ProcessAutoBidsJob.set(wait: 1.second).perform_later(auction_id)
  end

  def notify_outbid_users
    # Use a single query to get unique previous bidders
    previous_bidder_ids = auction.bids
      .where.not(user_id: user_id)
      .select('DISTINCT user_id')
      .limit(100)  # Limit to prevent overwhelming the system
      
    previous_bidder_ids.each do |bid|
      BidMailer.outbid_notification(bid.user_id, auction_id)
        .deliver_later(wait: 30.seconds)
    end
  end

  def broadcast_bid
    broadcast_updates_to_auction
  end

  def broadcast_updates_to_auction
    stream = [auction, "bids"]
    
    # Update current price
    broadcast_replace_to stream,
      target: "auction_#{auction.id}_current_price",
      partial: "auctions/current_price",
      locals: { auction: auction }

    # Update bid actions
    broadcast_replace_to stream,
      target: "auction_#{auction.id}_bid_actions",
      partial: "auctions/bid_actions",
      locals: { auction: auction }

    # Add the new bid to the history
    broadcast_prepend_to stream,
      target: "auction_#{auction.id}_bids",
      partial: "bids/bid",
      locals: { bid: self }
  end
end 