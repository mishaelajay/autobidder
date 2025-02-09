# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoBid, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:auction) }
  end

  describe 'validations' do
    it { should validate_presence_of(:maximum_amount) }
    it { should validate_numericality_of(:maximum_amount).is_greater_than(0) }
  end

  let(:seller) { create(:user) }
  let(:bidder) { create(:user) }
  let(:auction) { create(:auction, seller: seller) }
  let(:auto_bid) { build(:auto_bid, user: bidder, auction: auction) }

  describe 'custom validations' do
    context 'auction_must_be_active' do
      it 'is valid when auction is active' do
        expect(auto_bid).to be_valid
      end

      it 'is invalid when auction has ended' do
        auction.update!(ends_at: 1.hour.ago)
        expect(auto_bid).not_to be_valid
        expect(auto_bid.errors[:base]).to include('Cannot set auto bid on ended auction')
      end
    end

    context 'cannot_auto_bid_on_own_auction' do
      it 'is valid when bidder is not the seller' do
        expect(auto_bid).to be_valid
      end

      it 'is invalid when bidder is the seller' do
        auto_bid.user = seller
        expect(auto_bid).not_to be_valid
        expect(auto_bid.errors[:base]).to include('Cannot auto bid on your own auction')
      end
    end

    context 'maximum_amount_must_be_greater_than_current_price' do
      it 'is valid when maximum amount is greater than current price' do
        allow(auction).to receive(:current_price).and_return(100)
        auto_bid.maximum_amount = 150
        expect(auto_bid).to be_valid
      end

      it 'is invalid when maximum amount is less than current price' do
        allow(auction).to receive(:current_price).and_return(100)
        auto_bid.maximum_amount = 90
        expect(auto_bid).not_to be_valid
        expect(auto_bid.errors[:maximum_amount]).to include('must be greater than current price')
      end
    end

    context 'one_auto_bid_per_user_per_auction' do
      it 'is valid when user has no other auto bids for the auction' do
        expect(auto_bid).to be_valid
      end

      it 'is invalid when user already has an auto bid for the auction' do
        create(:auto_bid, user: bidder, auction: auction)
        expect(auto_bid).not_to be_valid
        expect(auto_bid.errors[:base]).to include('You already have an auto bid for this auction')
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'processes auto bids' do
        expect(AutoBidProcessor).to receive(:new)
          .with(auction)
          .and_return(double(process: true))

        auto_bid.save!
      end
    end
  end
end
