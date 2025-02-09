class AutoBid < ApplicationRecord
  belongs_to :user
  belongs_to :auction

  validates :maximum_amount, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :auction_id, message: "already has an auto bid for this auction" }
  
  validate :cannot_auto_bid_on_own_auction, if: -> { user.present? && auction.present? }
  validate :maximum_amount_must_be_greater_than_current_price, if: -> { maximum_amount.present? && auction.present? }
  validate :one_auto_bid_per_user_per_auction, if: -> { user.present? && auction.present? }
  validate :auction_must_be_active, if: -> { auction.present? }

  after_create :process_auto_bids

  private

  def cannot_auto_bid_on_own_auction
    if user_id == auction.seller_id
      errors.add(:base, "Cannot auto bid on your own auction")
    end
  end

  def maximum_amount_must_be_greater_than_current_price
    if maximum_amount <= auction.current_price
      errors.add(:maximum_amount, "must be greater than current price")
    end
  end

  def one_auto_bid_per_user_per_auction
    if user && auction && user.has_auto_bid_for?(auction) && !id
      errors.add(:base, "You already have an auto bid for this auction")
    end
  end

  def auction_must_be_active
    if auction.ended?
      errors.add(:base, "Cannot set auto bid on ended auction")
    end
  end

  def process_auto_bids
    AutoBidProcessor.new(auction).process
  end
end 