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
      let(:bidder) { create(:user) }
      
      before do
        # Create a bid to set the current price to 150
        create(:bid, auction: auction, amount: 150)
        # Create an auto bid with lower maximum amount, skipping validations
        auto_bid = build(:auto_bid, auction: auction, user: bidder, maximum_amount: 140)
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
      
      before do
        # Create initial bid and allow the next bid to be created with validation skipped
        create(:bid, auction: auction, user: highest_bidder, amount: 150)
        allow(Bid).to receive(:create!).and_call_original
        auto_bid = build(:auto_bid, auction: auction, user: lower_bidder, maximum_amount: 200)
        auto_bid.save(validate: false)
      end

      it 'does not create a bid if the next minimum bid exceeds maximum amount' do
        # Create a bid that would make the next minimum bid exceed the maximum amount
        # Skip validation since we're testing the processor's logic, not bid validation
        bid = build(:bid, auction: auction, amount: 190, user: highest_bidder)
        bid.save(validate: false)
        
        expect(Bid).not_to receive(:create!)
        processor.process
      end
    end

    context 'when auto bid matches current highest bid' do
      let(:bidder1) { create(:user) }
      let(:highest_bidder) { create(:user) }

      before do
        create(:bid, auction: auction, user: highest_bidder, amount: 150)
        auto_bid = build(:auto_bid, auction: auction, user: bidder1, maximum_amount: 160)
        auto_bid.save(validate: false)
      end

      it 'does not create a new bid' do
        expect(Bid).not_to receive(:create!)
        processor.process
      end
    end

    context 'with concurrent access' do
      let(:bidder) { create(:user) }
      let(:relation) { instance_double(ActiveRecord::Relation) }

      before do
        allow(auction).to receive(:active?).and_return(true)
        allow(auction).to receive(:auto_bids).and_return(relation)
        allow(relation).to receive(:exists?).and_return(true)
        allow(relation).to receive(:select).and_return(relation)
        allow(relation).to receive(:joins).and_return(relation)
        allow(relation).to receive(:where).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(relation).to receive(:lock).with('FOR UPDATE SKIP LOCKED').and_return(relation)
        allow(relation).to receive(:first).and_return(nil)
      end

      it 'uses database locking to prevent race conditions' do
        processor.process
        expect(relation).to have_received(:lock).with('FOR UPDATE SKIP LOCKED')
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
      let(:bidder) { create(:user) }
      
      before do
        create(:bid, auction: auction, amount: 150)
        auto_bid = build(:auto_bid, auction: auction, user: bidder, maximum_amount: 140)
        auto_bid.save(validate: false)
        allow(Bid).to receive(:create!)
      end

      it 'does not create any bids' do
        processor.process
        expect(Bid).not_to have_received(:create!)
      end
    end
  end
end
