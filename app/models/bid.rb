# frozen_string_literal: true

class Bid < ApplicationRecord
  paginates_per 25 # Set default pagination limit

  belongs_to :user
  belongs_to :auction, touch: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :user, :auction, presence: true

  validate :auction_must_be_active, if: -> { auction.present? }
  validate :amount_must_be_minimum_next_bid, if: -> { auction.present? }
  validate :cannot_bid_on_own_auction, if: -> { auction.present? && user.present? }

  after_create :process_auto_bids
  after_create :notify_outbid_users
  after_create_commit :broadcast_bid

  private

  def auction_must_be_active
    return unless auction.ended?

    errors.add(:base, 'Cannot bid on ended auction')
  end

  def amount_must_be_minimum_next_bid
    minimum_required = auction.minimum_next_bid
    return unless amount < minimum_required

    errors.add(:amount, "must be at least #{minimum_required}")
  end

  def cannot_bid_on_own_auction
    return unless user_id == auction.seller_id

    errors.add(:base, 'Cannot bid on your own auction')
  end

  def process_auto_bids
    AutoBidProcessor.new(auction).process
  end

  def notify_outbid_users
    # Get the latest bid for each user using a subquery
    previous_bids = auction.bids
                           .where.not(user_id: user_id)
                           .where(
                             id: auction.bids
                               .select('MAX(id)')
                               .group(:user_id)
                           )
                           .limit(100) # Limit to prevent overwhelming the system

    previous_bids.each do |bid|
      BidMailer.outbid_notification(bid)
               .deliver_later(wait: 30.seconds)
    end
  end

  def broadcast_bid
    broadcast_updates_to_auction
  end

  def broadcast_updates_to_auction
    stream = [auction, 'bids']

    # Update current price
    broadcast_replace_to stream,
                         target: "auction_#{auction.id}_current_price",
                         partial: 'auctions/current_price',
                         locals: { auction: auction }

    # Update bid actions
    broadcast_replace_to stream,
                         target: "auction_#{auction.id}_bid_actions",
                         partial: 'auctions/bid_actions',
                         locals: { auction: auction }

    # Add the new bid to the history
    broadcast_prepend_to stream,
                         target: "auction_#{auction.id}_bids",
                         partial: 'bids/bid',
                         locals: { bid: self }
  end
end
