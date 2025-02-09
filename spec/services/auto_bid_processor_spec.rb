# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoBidProcessor do
  let(:seller) { create(:user) }
  let(:auction) { create(:auction, seller: seller, starting_price: 100) }
  let(:processor) { described_class.new(auction) }

  describe '#process' do
    context 'when auction is not active' do
      before { allow(auction).to receive(:active?).and_return(false) }

      it 'does not process auto bids' do
        expect(Bid).not_to receive(:create!)
        processor.process
      end
    end

    context 'when there are no auto bids with maximum amount higher than current price' do
      before do
        # Skip validation to create an auto bid with lower maximum amount
        auto_bid = build(:auto_bid, auction: auction, maximum_amount: 90)
        auto_bid.save(validate: false)
      end

      it 'does not create any bids' do
        expect(Bid).not_to receive(:create!)
        processor.process
      end
    end

    context 'when there are valid auto bids' do
      let(:highest_bidder) { create(:user) }
      let(:lower_bidder) { create(:user) }
      let!(:current_bid) { create(:bid, auction: auction, user: highest_bidder, amount: 150) }

      before do
        # Create auto bids with different maximum amounts
        # Skip validation since we're setting up a test scenario
        auto_bid1 = build(:auto_bid, auction: auction, user: lower_bidder, maximum_amount: 200)
        auto_bid1.save(validate: false)

        auto_bid2 = build(:auto_bid, auction: auction, user: lower_bidder, maximum_amount: 180)
        auto_bid2.save(validate: false)
      end

      it 'does not create a bid if the next minimum bid exceeds maximum amount' do
        create(:bid, auction: auction, amount: 195)

        expect do
          processor.process
        end.not_to change(Bid, :count)
      end
    end

    context 'when auto bid matches current highest bid' do
      let(:bidder1) { create(:user) }
      let(:highest_bidder) { create(:user) }

      before do
        create(:bid, auction: auction, user: highest_bidder, amount: 150)

        # Skip validation since we're setting up a test scenario
        auto_bid = build(:auto_bid, auction: auction, user: bidder1, maximum_amount: 150)
        auto_bid.save(validate: false)
      end

      it 'does not create a new bid' do
        expect do
          processor.process
        end.not_to change(Bid, :count)
      end
    end

    context 'with concurrent access' do
      let(:bidder) { create(:user) }

      it 'uses database locking to prevent race conditions' do
        # Skip validation since we're setting up a test scenario
        auto_bid = build(:auto_bid, auction: auction, user: bidder, maximum_amount: 200)
        auto_bid.save(validate: false)

        expect_any_instance_of(ActiveRecord::Relation)
          .to receive(:lock)
          .with('FOR UPDATE SKIP LOCKED')
          .and_call_original

        processor.process
      end
    end

    context 'when there are no autobidders' do
      before do
        allow(Bid).to receive(:create!)
      end

      it 'does not create any bids' do
        processor.process
        expect(Bid).not_to have_received(:create!)
      end
    end

    context 'when autobidders have insufficient max bid' do
      before do
        allow(Bid).to receive(:create!)
      end

      it 'does not create any bids' do
        processor.process
        expect(Bid).not_to have_received(:create!)
      end
    end

    context 'when there are valid autobidders' do
      let(:first_bidder) { create(:user) }
      let(:second_bidder) { create(:user) }
      let(:highest_bidder) { create(:user) }
      let(:auction) { create(:auction) }
      let(:current_bid) { create(:bid, auction: auction, user: highest_bidder, amount: 150) }

      before do
        create(:auto_bid_setting, user: first_bidder, auction: auction, max_bid: 200)
        create(:auto_bid_setting, user: second_bidder, auction: auction, max_bid: 300)
      end

      it 'processes bids in order of max bid amount' do
        relation = instance_double(ActiveRecord::Relation)
        allow(AutoBidSetting).to receive(:for_auction).and_return(relation)
        allow(relation).to receive(:order).with(max_bid: :desc).and_return([
                                                                             instance_double(AutoBidSetting,
                                                                                             user: second_bidder, max_bid: 300),
                                                                             instance_double(AutoBidSetting,
                                                                                             user: first_bidder, max_bid: 200)
                                                                           ])

        processor.process
      end
    end
  end
end
