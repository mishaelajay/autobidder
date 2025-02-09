# frozen_string_literal: true

# AutoBid model representing automatic bidding settings for users.
# Allows users to set maximum bid amounts and automatically outbid others up to that amount.
class AutoBid < ApplicationRecord
  belongs_to :user
  belongs_to :auction

  validates :maximum_amount, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :auction_id, message: -> { I18n.t('auto_bids.errors.already_exists') } }

  validate :cannot_auto_bid_on_own_auction, if: -> { user.present? && auction.present? }
  validate :maximum_amount_must_be_greater_than_current_price, if: -> { maximum_amount.present? && auction.present? }
  validate :one_auto_bid_per_user_per_auction, if: -> { user.present? && auction.present? }
  validate :auction_must_be_active, if: -> { auction.present? }

  scope :for_auction, ->(auction) { where(auction: auction) }

  private

  def cannot_auto_bid_on_own_auction
    return unless user_id == auction.seller_id

    errors.add(:base, 'Cannot auto bid on your own auction')
  end

  def maximum_amount_must_be_greater_than_current_price
    return unless maximum_amount <= auction.current_price

    errors.add(:maximum_amount, 'must be greater than current price')
  end

  def one_auto_bid_per_user_per_auction
    return unless user && auction && user.has_auto_bid_for?(auction) && !id

    errors.add(:base, 'You already have an auto bid for this auction')
  end

  def auction_must_be_active
    return unless auction.ended?

    errors.add(:base, 'Cannot set auto bid on ended auction')
  end
end
