# frozen_string_literal: true

module AuctionTestHelper
  def create_test_auction(user, options = {})
    Auction.create!({
      seller: user,
      title: 'Test Auction',
      description: 'Test Description',
      starting_price: 10.00,
      minimum_selling_price: 50.00,
      ends_at: 24.hours.from_now
    }.merge(options))
  end

  def place_bid(auction, user, amount)
    Bid.create!(
      auction: auction,
      user: user,
      amount: amount
    )
  end

  def create_auto_bid(auction, user, max_amount)
    AutoBid.create!(
      auction: auction,
      user: user,
      maximum_amount: max_amount
    )
  end
end
