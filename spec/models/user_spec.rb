require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:bids).dependent(:destroy) }
    it { should have_many(:auto_bids).dependent(:destroy) }
    it { should have_many(:auctions).with_foreign_key('seller_id').dependent(:destroy) }
    it { should have_many(:won_auctions).class_name('Auction').with_foreign_key('winning_bidder_id') }
  end

  describe 'validations' do
    subject { create(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
  end

  let(:user) { create(:user) }
  let(:auction) { create(:auction, seller: create(:user)) }

  describe 'instance methods' do
    describe '#has_auto_bid_for?' do
      it 'returns true when user has auto bid for the auction' do
        create(:auto_bid, user: user, auction: auction)
        expect(user.has_auto_bid_for?(auction)).to be true
      end

      it 'returns false when user has no auto bid for the auction' do
        expect(user.has_auto_bid_for?(auction)).to be false
      end
    end

    describe '#current_auto_bid_for' do
      it 'returns the auto bid when user has one for the auction' do
        auto_bid = create(:auto_bid, user: user, auction: auction)
        expect(user.current_auto_bid_for(auction)).to eq(auto_bid)
      end

      it 'returns nil when user has no auto bid for the auction' do
        expect(user.current_auto_bid_for(auction)).to be_nil
      end
    end

    describe '#highest_bid_for' do
      it 'returns the highest bid when user has bids for the auction' do
        create(:bid, user: user, auction: auction, amount: 100)
        highest_bid = create(:bid, user: user, auction: auction, amount: 200)
        expect(user.highest_bid_for(auction)).to eq(highest_bid)
      end

      it 'returns nil when user has no bids for the auction' do
        expect(user.highest_bid_for(auction)).to be_nil
      end
    end
  end

  describe 'scopes' do
    describe '.active_sellers' do
      it 'returns users with active auctions' do
        seller_with_active = create(:user)
        seller_with_ended = create(:user)
        buyer = create(:user)

        create(:auction, seller: seller_with_active, ends_at: 1.day.from_now)
        create(:auction, :ended, seller: seller_with_ended)

        expect(User.active_sellers).to include(seller_with_active)
        expect(User.active_sellers).not_to include(seller_with_ended)
        expect(User.active_sellers).not_to include(buyer)
      end
    end

    describe '.active_bidders' do
      it 'returns users with bids on active auctions' do
        bidder_on_active = create(:user)
        bidder_on_ended = create(:user)
        non_bidder = create(:user)

        active_auction = create(:auction, ends_at: 1.day.from_now)
        ended_auction = create(:auction, :ended)

        create(:bid, user: bidder_on_active, auction: active_auction)
        create(:bid, :for_ended_auction, user: bidder_on_ended, auction: ended_auction)

        expect(User.active_bidders).to include(bidder_on_active)
        expect(User.active_bidders).not_to include(bidder_on_ended)
        expect(User.active_bidders).not_to include(non_bidder)
      end
    end
  end
end 