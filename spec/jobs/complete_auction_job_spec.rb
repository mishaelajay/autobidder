# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompleteAuctionJob do
  include ActiveJob::TestHelper

  let(:seller) { create(:user) }
  let(:bidder) { create(:user) }
  let(:auction) { create(:auction, seller: seller, ends_at: 1.hour.ago) }

  describe '#perform' do
    context 'when auction has a winning bid' do
      let!(:winning_bid) { create(:bid, auction: auction, user: bidder, amount: 100) }

      it 'completes the auction with the winning bid' do
        expect do
          perform_enqueued_jobs { described_class.perform_later(auction.id) }
        end.to change { auction.reload.completed? }.from(false).to(true)
                                                   .and change(auction, :winning_bid_id).to(winning_bid.id)
      end

      it 'sends notifications' do
        expect(AuctionMailer).to receive(:winner_notification)
          .with(bidder, auction)
          .and_return(double(deliver_later: true))

        expect(AuctionMailer).to receive(:seller_auction_completed)
          .with(seller, auction, winning_bid)
          .and_return(double(deliver_later: true))

        perform_enqueued_jobs { described_class.perform_later(auction.id) }
      end

      it 'notifies external system' do
        expect(ExternalSystemNotifierJob).to receive(:perform_later)
          .with(
            event: 'auction_completed',
            auction_id: auction.id,
            winner_id: bidder.id,
            winning_amount: winning_bid.amount,
            completed_at: anything
          )

        perform_enqueued_jobs { described_class.perform_later(auction.id) }
      end
    end

    context 'when auction has no bids' do
      it 'completes the auction without a winning bid' do
        expect do
          perform_enqueued_jobs { described_class.perform_later(auction.id) }
        end.to change { auction.reload.completed? }.from(false).to(true)
      end

      it 'notifies seller about no winner' do
        expect(AuctionMailer).to receive(:seller_auction_no_winner)
          .with(seller, auction)
          .and_return(double(deliver_later: true))

        perform_enqueued_jobs { described_class.perform_later(auction.id) }
      end

      it 'notifies external system about no winner' do
        expect(ExternalSystemNotifierJob).to receive(:perform_later)
          .with(
            event: 'auction_completed',
            auction_id: auction.id,
            winner_id: nil,
            winning_amount: nil,
            completed_at: anything
          )

        perform_enqueued_jobs { described_class.perform_later(auction.id) }
      end
    end

    context 'when auction is already completed' do
      before { auction.update!(completed_at: Time.current) }

      it 'does not process the auction again' do
        expect(AuctionMailer).not_to receive(:winner_notification)
        expect(AuctionMailer).not_to receive(:seller_auction_completed)
        expect(AuctionMailer).not_to receive(:seller_auction_no_winner)
        expect(ExternalSystemNotifierJob).not_to receive(:perform_later)

        perform_enqueued_jobs { described_class.perform_later(auction.id) }
      end
    end

    context 'when auction has not ended yet' do
      let(:auction) { create(:auction, seller: seller, ends_at: 1.hour.from_now) }

      it 'does not process the auction' do
        expect(AuctionMailer).not_to receive(:winner_notification)
        expect(AuctionMailer).not_to receive(:seller_auction_completed)
        expect(AuctionMailer).not_to receive(:seller_auction_no_winner)
        expect(ExternalSystemNotifierJob).not_to receive(:perform_later)

        perform_enqueued_jobs { described_class.perform_later(auction.id) }
      end
    end
  end
end
