# frozen_string_literal: true

class Auction < ApplicationRecord
  belongs_to :seller, class_name: 'User'
  belongs_to :winning_bid, class_name: 'Bid', optional: true

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
  scope :ended, -> { where('ends_at <= ?', Time.current) }
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
    case current_price
    when 0..0.99 then 0.05
    when 1..4.99 then 0.25
    when 5..24.99 then 0.50
    when 25..99.99 then 1.00
    when 100..249.99 then 2.50
    when 250..499.99 then 5.00
    when 500..999.99 then 10.00
    else 25.00
    end
  end
end
