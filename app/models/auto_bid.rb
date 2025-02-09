class AutoBid < ApplicationRecord
  belongs_to :user
  belongs_to :auction

  validates :maximum_amount, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :auction_id, message: "already has an auto bid for this auction" }
  
  validate :cannot_auto_bid_on_own_auction
  validate :maximum_amount_must_be_greater_than_current_price
  validate :auction_must_be_active

  private

  def cannot_auto_bid_on_own_auction
    if user_id == auction.seller_id
      errors.add(:base, "Cannot set auto bid on your own auction")
    end
  end

  def maximum_amount_must_be_greater_than_current_price
    if maximum_amount <= auction.current_price
      errors.add(:maximum_amount, "must be greater than current auction price (#{auction.current_price})")
    end
  end

  def auction_must_be_active
    if auction.ended?
      errors.add(:base, "Cannot set auto bid on ended auction")
    end
  end
end 