require 'rails_helper'

RSpec.describe Bid, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:auction).touch(true) }
  end

  describe 'validations' do
    it { should validate_presence_of(:amount) }
    it { should validate_numericality_of(:amount).is_greater_than(0) }
  end

  let(:seller) { create(:user) }
  let(:bidder) { create(:user) }
  let(:auction) { create(:auction, seller: seller, starting_price: 100) }
  let(:bid) { build(:bid, user: bidder, auction: auction, amount: 150) }

  describe 'custom validations' do
    context 'auction_must_be_active' do
      it 'is valid when auction is active' do
        expect(bid).to be_valid
      end

      it 'is invalid when auction has ended' do
        auction.update!(ends_at: 1.hour.ago)
        expect(bid).not_to be_valid
        expect(bid.errors[:base]).to include("Cannot bid on ended auction")
      end
    end

    context 'cannot_bid_on_own_auction' do
      it 'is valid when bidder is not the seller' do
        expect(bid).to be_valid
      end

      it 'is invalid when bidder is the seller' do
        bid.user = seller
        expect(bid).not_to be_valid
        expect(bid.errors[:base]).to include("Cannot bid on your own auction")
      end
    end

    context 'amount_must_meet_minimum_next_bid' do
      it 'is valid when amount meets minimum next bid' do
        allow(auction).to receive(:minimum_next_bid).and_return(150)
        expect(bid).to be_valid
      end

      it 'is invalid when amount is less than minimum next bid' do
        allow(auction).to receive(:minimum_next_bid).and_return(200)
        expect(bid).not_to be_valid
        expect(bid.errors[:amount]).to include("must be at least #{auction.minimum_next_bid}")
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'processes auto bids' do
        expect(AutoBidProcessor).to receive(:new)
          .with(auction)
          .and_return(double(process: true))
        
        bid.save!
      end

      it 'notifies outbid users' do
        previous_bid = create(:bid, auction: auction, amount: 120)
        expect(BidMailer).to receive(:outbid_notification)
          .with(previous_bid)
          .and_return(double(deliver_later: true))
        
        bid.save!
      end
    end
  end

  describe 'pagination' do
    it 'sets default per page to 25' do
      expect(Bid.default_per_page).to eq(25)
    end
  end
end 