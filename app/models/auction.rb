class Auction < ApplicationRecord
  belongs_to :seller, class_name: 'User'
  has_many :bids, dependent: :destroy
  has_many :auto_bids, dependent: :destroy
  has_many :bidders, through: :bids, source: :user

  broadcasts

  validates :title, presence: true
  validates :description, presence: true
  validates :starting_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_selling_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ends_at, presence: true

  validate :ends_at_must_be_future, on: :create

  scope :active, -> { where('ends_at > ?', Time.current) }
  scope :ended, -> { where('ends_at <= ?', Time.current) }
  scope :won, -> { ended.joins(:bids).where('bids.amount >= auctions.minimum_selling_price') }
  scope :unsold, -> { ended.left_joins(:bids).where('bids.id IS NULL OR bids.amount < auctions.minimum_selling_price') }

  broadcasts_to ->(auction) { [auction, "bids"] }

  def active?
    ends_at > Time.current
  end

  def ended?
    !active?
  end

  def current_highest_bid
    bids.order(amount: :desc).first
  end

  def current_price
    current_highest_bid&.amount || starting_price
  end

  def minimum_next_bid
    [starting_price, current_highest_bid&.amount.to_f + minimum_bid_increment].max
  end

  def winner
    return nil unless ended?
    highest_bid = current_highest_bid
    return nil if highest_bid.nil? || highest_bid.amount < minimum_selling_price
    highest_bid.user
  end

  def formatted_current_price
    ActionController::Base.helpers.number_to_currency(current_price)
  end

  private

  def ends_at_must_be_future
    if ends_at.present? && ends_at <= Time.current
      errors.add(:ends_at, "must be in the future")
    end
  end

  def minimum_bid_increment
    current_price = current_highest_bid&.amount.to_f
    case current_price
    when 0..0.99 then 0.05
    when 1..4.99 then 0.25
    when 5..24.99 then 0.5
    when 25..99.99 then 1
    when 100..249.99 then 2.5
    when 250..499.99 then 5
    when 500..999.99 then 10
    else 25
    end
  end
end 