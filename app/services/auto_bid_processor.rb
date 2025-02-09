# frozen_string_literal: true

# Service class that handles the processing of automatic bids.
# Manages the logic for placing automatic bids based on user-defined maximum amounts.
class AutoBidProcessor
  def initialize(auction)
    @auction = auction
  end

  def process
    return unless should_process?

    next_auto_bid = fetch_next_auto_bid
    return unless next_auto_bid

    place_auto_bid(next_auto_bid)
  end

  private

  def should_process?
    @auction.active? &&
      @auction.auto_bids.exists?(['maximum_amount > ?', @auction.current_price])
  end

  def fetch_next_auto_bid
    @auction.auto_bids
            .select('auto_bids.*, users.id as user_id')
            .joins(:user)
            .where('maximum_amount > ?', @auction.current_price)
            .order('maximum_amount DESC, created_at ASC')
            .lock('FOR UPDATE SKIP LOCKED')
            .first
  end

  def place_auto_bid(auto_bid)
    current_price = @auction.current_price
    next_minimum_bid = calculate_next_minimum_bid(current_price)
    bid_amount = [next_minimum_bid, auto_bid.maximum_amount].min

    create_bid(auto_bid.user_id, bid_amount)
  end

  def create_bid(user_id, amount)
    bid = Bid.create!(
      user_id: user_id,
      auction_id: @auction.id,
      amount: amount
    )

    # Recursively process next auto bid if available
    process if bid.persisted?
  end

  def calculate_next_minimum_bid(current_price)
    current_price + calculate_increment(current_price)
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
