# frozen_string_literal: true

# Service class that handles the processing of automatic bids.
# Manages the logic for placing automatic bids based on user-defined maximum amounts.
class AutoBidProcessor
  def initialize(auction)
    @auction = auction
  end

  def process
    return unless should_process?

    current_highest_bid, next_auto_bid = fetch_bids
    return unless next_auto_bid

    place_auto_bid(current_highest_bid, next_auto_bid)
  end

  private

  def should_process?
    @auction.active? &&
      @auction.auto_bids.exists?(['maximum_amount > ?', @auction.current_price])
  end

  def fetch_bids
    current_price = @auction.current_price
    bid_data = fetch_bid_data(current_price)
    parse_bid_data(bid_data)
  end

  def fetch_bid_data(current_price)
    @auction.bids
            .select(bid_select_fields)
            .joins(auto_bids_join)
            .where('auto_bids.maximum_amount > ? AND auto_bids.user_id != bids.user_id', current_price)
            .order('bids.amount DESC, auto_bids.maximum_amount DESC, auto_bids.created_at ASC')
            .lock('FOR UPDATE SKIP LOCKED')
            .limit(1)
            .first
  end

  def bid_select_fields
    'bids.user_id, bids.amount, ' \
      'auto_bids.id AS auto_bid_id, ' \
      'auto_bids.user_id AS auto_bid_user_id, ' \
      'auto_bids.maximum_amount'
  end

  def auto_bids_join
    'LEFT JOIN auto_bids ON auto_bids.auction_id = bids.auction_id'
  end

  def parse_bid_data(bid_data)
    return [nil, nil] unless bid_data

    current_highest_bid = bid_data.slice(:user_id, :amount)
    next_auto_bid = bid_data.slice(:auto_bid_id, :auto_bid_user_id, :maximum_amount)

    [current_highest_bid, next_auto_bid]
  end

  def place_auto_bid(current_highest_bid, next_auto_bid)
    current_amount = current_highest_bid ? current_highest_bid['amount'] : @auction.starting_price
    next_minimum_bid = calculate_next_minimum_bid(current_amount)
    bid_amount = [next_minimum_bid, next_auto_bid['maximum_amount']].min

    create_bid(next_auto_bid['auto_bid_user_id'], bid_amount)
  end

  def create_bid(user_id, amount)
    Bid.create!(
      user_id: user_id,
      auction_id: @auction.id,
      amount: amount
    )
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
