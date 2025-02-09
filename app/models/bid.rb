# frozen_string_literal: true

# Bid model representing a bid placed on an auction.
# Handles bid validation, notification, and broadcasting updates.
class Bid < ApplicationRecord
  paginates_per 25 # Set default pagination limit

  belongs_to :user
  belongs_to :auction, touch: true

  validates :amount, presence: true, numericality: { greater_than: 0 }

  validate :auction_must_be_active, if: -> { auction.present? }
  validate :amount_must_be_minimum_next_bid, if: -> { auction.present? }
  validate :cannot_bid_on_own_auction, if: -> { auction.present? && user.present? }

  attr_accessor :skip_auto_bid_processing

  after_create :process_auto_bids, unless: :skip_auto_bid_processing
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
    previous_bids = find_previous_bids
    send_outbid_notifications(previous_bids)
  end

  def find_previous_bids
    auction.bids
           .where.not(user_id: user_id)
           .where(id: latest_bids_subquery)
           .limit(100)
  end

  def latest_bids_subquery
    auction.bids
           .select('MAX(id)')
           .group(:user_id)
  end

  def send_outbid_notifications(bids)
    bids.each do |bid|
      BidMailer.outbid_notification(bid)
               .deliver_later(wait: 30.seconds)
    end
  end

  def broadcast_bid
    broadcast_updates_to_auction
  end

  def broadcast_updates_to_auction
    stream = [auction, 'bids']
    broadcast_price_update(stream)
    broadcast_bid_actions(stream)
    broadcast_new_bid(stream)
  end

  def broadcast_price_update(stream)
    broadcast_replace_to stream,
                         target: "auction_#{auction.id}_current_price",
                         partial: 'auctions/current_price',
                         locals: { auction: auction }
  end

  def broadcast_bid_actions(stream)
    broadcast_replace_to stream,
                         target: "auction_#{auction.id}_bid_actions",
                         partial: 'auctions/bid_actions',
                         locals: { auction: auction }
  end

  def broadcast_new_bid(stream)
    broadcast_prepend_to stream,
                         target: "auction_#{auction.id}_bids",
                         partial: 'bids/bid',
                         locals: { bid: self }
  end
end
