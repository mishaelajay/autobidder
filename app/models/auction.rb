# frozen_string_literal: true

# Auction model representing items being auctioned in the system.
# Handles auction lifecycle, bidding rules, and completion logic.
class Auction < ApplicationRecord
  belongs_to :seller, class_name: 'User'
  belongs_to :winning_bid, class_name: 'Bid', optional: true
  belongs_to :winning_bidder, class_name: 'User', optional: true

  has_many :bids, dependent: :destroy
  has_many :bidders, through: :bids, source: :user
  has_many :auto_bids, dependent: :destroy

  broadcasts

  validates :title, presence: true
  validates :description, presence: true
  validates :starting_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_selling_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :ends_at, presence: true

  validate :ends_at_must_be_future, on: :create

  after_create :schedule_completion_job

  scope :active, -> { where('ends_at > ?', Time.current) }
  scope :ended, -> { where(ends_at: ..Time.current) }
  scope :won, -> { ended.joins(:bids).where('bids.amount >= auctions.minimum_selling_price') }
  scope :unsold, -> { ended.left_joins(:bids).where('bids.id IS NULL OR bids.amount < auctions.minimum_selling_price') }

  broadcasts_to ->(auction) { [auction, 'bids'] }

  def active?
    !ended? && !completed?
  end

  def ended?
    ends_at <= Time.current
  end

  def completed?
    completed_at.present?
  end

  def current_highest_bid
    bids.order(amount: :desc).first
  end

  def current_price
    bids.maximum(:amount) || starting_price
  end

  def minimum_next_bid
    current_price + calculate_increment(current_price)
  end

  def winner
    winning_bid&.user
  end

  def formatted_current_price
    ActionController::Base.helpers.number_to_currency(current_price)
  end

  private

  def ends_at_must_be_future
    return unless ends_at.present? && ends_at <= Time.current

    errors.add(:ends_at, 'must be in the future')
  end

  def schedule_completion_job
    delay = ends_at - Time.current
    CompleteAuctionJob.set(wait: delay).perform_later(id)
  end

  def calculate_increment(current_price)
    increment_rules.each do |range, increment|
      return increment if range.include?(current_price)
    end
    25.00 # Default increment for prices over 1000
  end

  def increment_rules
    {
      (0..0.99) => 0.05,
      (1..4.99) => 0.25,
      (5..24.99) => 0.50,
      (25..99.99) => 1.00,
      (100..249.99) => 2.50,
      (250..499.99) => 5.00,
      (500..999.99) => 10.00
    }
  end
end
