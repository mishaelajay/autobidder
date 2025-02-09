require 'rails_helper'

RSpec.describe Auction, type: :model do
  describe 'associations' do
    it { should belong_to(:seller).class_name('User') }
    it { should belong_to(:winning_bid).class_name('Bid').optional }
    it { should have_many(:bids).dependent(:destroy) }
    it { should have_many(:bidders).through(:bids).source(:user) }
    it { should have_many(:auto_bids).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:starting_price) }
    it { should validate_presence_of(:minimum_selling_price) }
    it { should validate_presence_of(:ends_at) }
    
    it { should validate_numericality_of(:starting_price).is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:minimum_selling_price).is_greater_than_or_equal_to(0) }
  end

  let(:seller) { create(:user) }
  let(:auction) { build(:auction, seller: seller) }

  describe 'custom validations' do
    context 'ends_at_must_be_future' do
      it 'is valid when ends_at is in the future' do
        auction.ends_at = 1.day.from_now
        expect(auction).to be_valid
      end

      it 'is invalid when ends_at is in the past' do
        auction.ends_at = 1.day.ago
        expect(auction).not_to be_valid
        expect(auction.errors[:ends_at]).to include("must be in the future")
      end
    end
  end

  describe 'scopes' do
    let!(:active_auction) { create(:auction, ends_at: 1.day.from_now) }
    let!(:ended_auction) { create(:ended_auction) }
    let!(:won_auction) do
      auction = create(:ended_auction)
      create(:bid, :for_ended_auction, auction: auction, amount: auction.minimum_selling_price + 10)
      auction
    end
    let!(:unsold_auction) do
      auction = create(:ended_auction)
      create(:bid, :for_ended_auction, auction: auction, amount: auction.minimum_selling_price - 10)
      auction
    end

    describe '.active' do
      it 'includes auctions that have not ended' do
        expect(Auction.active).to include(active_auction)
      end

      it 'excludes auctions that have ended' do
        expect(Auction.active).not_to include(ended_auction)
      end
    end

    describe '.ended' do
      it 'includes auctions that have ended' do
        expect(Auction.ended).to include(ended_auction)
      end

      it 'excludes auctions that have not ended' do
        expect(Auction.ended).not_to include(active_auction)
      end
    end

    describe '.won' do
      it 'includes auctions with winning bids' do
        expect(Auction.won).to include(won_auction)
      end

      it 'excludes auctions without winning bids' do
        expect(Auction.won).not_to include(unsold_auction)
      end
    end

    describe '.unsold' do
      it 'includes auctions without winning bids' do
        expect(Auction.unsold).to include(unsold_auction)
      end

      it 'excludes auctions with winning bids' do
        expect(Auction.unsold).not_to include(won_auction)
      end
    end
  end

  describe 'instance methods' do
    describe '#active?' do
      it 'returns true when auction has not ended and is not completed' do
        auction.ends_at = 1.day.from_now
        expect(auction.active?).to be true
      end

      it 'returns false when auction has ended' do
        auction.ends_at = 1.day.ago
        expect(auction.active?).to be false
      end

      it 'returns false when auction is completed' do
        auction.completed_at = Time.current
        expect(auction.active?).to be false
      end
    end

    describe '#ended?' do
      it 'returns true when auction has ended' do
        auction.ends_at = 1.day.ago
        expect(auction.ended?).to be true
      end

      it 'returns false when auction has not ended' do
        auction.ends_at = 1.day.from_now
        expect(auction.ended?).to be false
      end
    end

    describe '#current_price' do
      it 'returns starting_price when there are no bids' do
        expect(auction.current_price).to eq(auction.starting_price)
      end

      it 'returns highest bid amount when there are bids' do
        auction.save!
        create(:bid, auction: auction, amount: 100)
        create(:bid, auction: auction, amount: 200)
        expect(auction.current_price).to eq(200)
      end
    end

    describe '#minimum_next_bid' do
      it 'calculates correct increment based on current price' do
        auction.save!
        
        {
          0.50 => 0.05,    # 0-0.99
          2.00 => 0.25,    # 1-4.99
          10.00 => 0.50,   # 5-24.99
          50.00 => 1.00,   # 25-99.99
          150.00 => 2.50,  # 100-249.99
          300.00 => 5.00,  # 250-499.99
          750.00 => 10.00, # 500-999.99
          1500.00 => 25.00 # 1000+
        }.each do |current_price, expected_increment|
          allow(auction).to receive(:current_price).and_return(current_price)
          expect(auction.minimum_next_bid).to eq(current_price + expected_increment)
        end
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'schedules completion job' do
        auction.ends_at = 1.day.from_now
        
        expect(CompleteAuctionJob).to receive(:set)
          .with(hash_including(wait: be_within(1.second).of(1.day)))
          .and_return(double(perform_later: true))
        
        auction.save!
      end
    end
  end
end 