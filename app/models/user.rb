# frozen_string_literal: true

# User model representing a registered user in the system.
# Users can be both sellers (creating auctions) and bidders (placing bids).
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  has_many :auctions, foreign_key: :seller_id, dependent: :destroy, inverse_of: :seller
  has_many :bids, dependent: :destroy
  has_many :bidded_auctions, through: :bids, source: :auction
  has_many :auto_bids, dependent: :destroy
  has_many :won_auctions, class_name: 'Auction', foreign_key: 'winning_bidder_id',
                          dependent: :nullify, inverse_of: :winning_bidder

  validates :name, presence: true

  scope :active_sellers, lambda {
    joins(:auctions)
      .where('auctions.ends_at > ?', Time.current)
      .distinct
  }

  scope :active_bidders, lambda {
    joins(:bids)
      .joins('INNER JOIN auctions ON bids.auction_id = auctions.id')
      .where('auctions.ends_at > ?', Time.current)
      .distinct
  }

  scope :with_active_auctions, lambda {
    joins(:auctions)
      .where('auctions.ends_at > ? AND auctions.completed_at IS NULL', Time.current)
      .distinct
  }

  scope :with_bids_on_active_auctions, lambda {
    joins(:bids)
      .joins('INNER JOIN auctions ON bids.auction_id = auctions.id')
      .where('auctions.ends_at > ?', Time.current)
      .distinct
  }

  def has_auto_bid_for?(auction)
    auto_bids.exists?(auction: auction)
  end
  alias_method :auto_bid_for?, :has_auto_bid_for?

  def current_auto_bid_for(auction)
    auto_bids.find_by(auction: auction)
  end

  def highest_bid_for(auction)
    bids.where(auction: auction).order(amount: :desc).first
  end
end
