require 'rails_helper'

RSpec.describe Auction, type: :model do
  let(:seller) { User.create!(name: 'Seller', email: 'seller@test.com', password: 'password') }
  let(:buyer) { User.create!(name: 'Buyer', email: 'buyer@test.com', password: 'password') }
  
  describe 'validations' do
    it 'requires a title' do
      auction = Auction.new(title: nil)
      auction.valid?
      expect(auction.errors[:title]).to include("can't be blank")
    end

    it 'requires ends_at to be in the future' do
      auction = Auction.new(ends_at: 1.day.ago)
      auction.valid?
      expect(auction.errors[:ends_at]).to include("must be in the future")
    end
  end

  describe '#current_price' do
    let(:auction) { create_test_auction(seller) }

    it 'returns starting price when no bids exist' do
      expect(auction.current_price).to eq(auction.starting_price)
    end

    it 'returns highest bid amount when bids exist' do
      place_bid(auction, buyer, 20.00)
      expect(auction.current_price).to eq(20.00)
    end
  end

  describe 'auto bidding' do
    let(:auction) { create_test_auction(seller) }
    let(:auto_bidder) { User.create!(name: 'Auto', email: 'auto@test.com', password: 'password') }

    it 'automatically places bid when outbid' do
      create_auto_bid(auction, auto_bidder, 30.00)
      place_bid(auction, buyer, 15.00)
      
      expect(auction.current_highest_bid.user).to eq(auto_bidder)
      expect(auction.current_highest_bid.amount).to be > 15.00
    end
  end
end 