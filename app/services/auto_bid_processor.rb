class AutoBidProcessor
  def initialize(auction)
    @auction = auction
  end

  def process
    return unless should_process?

    # Use a single query to get both the current highest bid and the next auto bid
    current_highest_bid, next_auto_bid = fetch_bids

    return unless next_auto_bid

    # Calculate and place the bid
    current_amount = current_highest_bid ? current_highest_bid['amount'] : @auction.starting_price
    next_minimum_bid = calculate_next_minimum_bid(current_amount)
    bid_amount = [next_minimum_bid, next_auto_bid['maximum_amount']].min
    
    Bid.create!(
      user_id: next_auto_bid['auto_bid_user_id'],
      auction_id: @auction.id,
      amount: bid_amount
    )
  end

  private

  def should_process?
    @auction.active? && 
    @auction.auto_bids.where('maximum_amount > ?', @auction.current_price).exists?
  end

  def fetch_bids
    current_price = @auction.bids.maximum(:amount) || @auction.starting_price

    # Use a single query to fetch both the current highest bid and the next auto bid
    bids = @auction.bids
      .select('bids.user_id, bids.amount, auto_bids.id AS auto_bid_id, auto_bids.user_id AS auto_bid_user_id, auto_bids.maximum_amount')
      .joins('LEFT JOIN auto_bids ON auto_bids.auction_id = bids.auction_id')
      .where('auto_bids.maximum_amount > ? AND auto_bids.user_id != bids.user_id', current_price)
      .order('bids.amount DESC, auto_bids.maximum_amount DESC, auto_bids.created_at ASC')
      .lock('FOR UPDATE SKIP LOCKED')
      .limit(1)
      .first

    current_highest_bid = bids&.slice(:user_id, :amount)
    next_auto_bid = bids&.slice(:auto_bid_id, :auto_bid_user_id, :maximum_amount)

    [current_highest_bid, next_auto_bid]
  end

  def calculate_next_minimum_bid(current_price)
    current_price + calculate_increment(current_price)
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