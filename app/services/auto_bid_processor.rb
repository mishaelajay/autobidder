class AutoBidProcessor
  def initialize(auction)
    @auction = auction
  end

  def process
    return unless should_process?

    # Get the current highest bid in a single query
    current_highest_bid = @auction.bids.select(:user_id, :amount).order(amount: :desc).first
    current_price = current_highest_bid&.amount || @auction.starting_price
    
    # Find the next highest auto bid in a single optimized query
    next_auto_bid = @auction.auto_bids
      .where('maximum_amount > ? AND user_id != ?', current_price, current_highest_bid&.user_id || 0)
      .select(:id, :user_id, :maximum_amount)
      .order(maximum_amount: :desc, created_at: :asc)
      .lock("FOR UPDATE SKIP LOCKED")
      .first

    return unless next_auto_bid

    # Calculate and place the bid
    next_minimum_bid = calculate_next_minimum_bid(current_price)
    bid_amount = [next_minimum_bid, next_auto_bid.maximum_amount].min
    
    Bid.create!(
      user_id: next_auto_bid.user_id,
      auction_id: @auction.id,
      amount: bid_amount
    )
  end

  private

  def should_process?
    @auction.active? && 
    @auction.auto_bids.where('maximum_amount > ?', @auction.current_price).exists?
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