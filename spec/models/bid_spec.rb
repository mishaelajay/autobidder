# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bid do
  let(:bid) { build(:bid, user: bidder, auction: auction, amount: 150) }
  let(:auction) { create(:auction, seller: seller, starting_price: 100) }
  let(:bidder) { create(:user) }
  let(:seller) { create(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:auction).touch(true) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  end

  describe 'custom validations' do
    context 'auction_must_be_active' do
      it 'is valid when auction is active' do
        expect(bid).to be_valid
      end

      it 'is invalid when auction has ended' do
        auction.update!(ends_at: 1.hour.ago)
        expect(bid).not_to be_valid
        expect(bid.errors[:base]).to include('Cannot bid on ended auction')
      end
    end

    context 'cannot_bid_on_own_auction' do
      it 'is valid when bidder is not the seller' do
        expect(bid).to be_valid
      end

      it 'is invalid when bidder is the seller' do
        bid.user = seller
        expect(bid).not_to be_valid
        expect(bid.errors[:base]).to include('Cannot bid on your own auction')
      end
    end

    context 'amount_must_meet_minimum_next_bid' do
      it 'is valid when amount meets minimum next bid' do
        allow(auction).to receive(:minimum_next_bid).and_return(150)
        expect(bid).to be_valid
      end

      it 'is invalid when amount is below minimum next bid' do
        allow(auction).to receive(:minimum_next_bid).and_return(200)
        expect(bid).not_to be_valid
      end

      it 'has the correct error message when amount is too low' do
        allow(auction).to receive(:minimum_next_bid).and_return(200)
        bid.valid?
        expect(bid.errors[:amount]).to include("must be at least #{auction.minimum_next_bid}")
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      let(:processor) { instance_spy(AutoBidProcessor, process: true) }

      before do
        allow(AutoBidProcessor).to receive(:new).with(auction).and_return(processor)
      end

      it 'processes auto bids' do
        bid.save!
        expect(processor).to have_received(:process)
      end

      it 'notifies outbid users' do
        mailer = instance_spy(ActionMailer::MessageDelivery)
        previous_bid = create(:bid, auction: auction, amount: 120)

        allow(BidMailer).to receive(:outbid_notification)
          .with(previous_bid)
          .and_return(mailer)

        bid.save!
        expect(mailer).to have_received(:deliver_later)
      end
    end
  end

  describe 'pagination' do
    it 'sets default per page to 25' do
      expect(described_class.default_per_page).to eq(25)
    end
  end
end
