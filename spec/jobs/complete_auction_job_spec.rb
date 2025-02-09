# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompleteAuctionJob do
  include ActiveJob::TestHelper

  let(:seller) { create(:user) }
  let(:bidder) { create(:user) }
  let(:auction) { create(:auction, seller: seller, ends_at: 1.hour.ago) }
  let(:mailer) { instance_spy(ActionMailer::MessageDelivery) }
  let(:auction_mailer) do
    class_spy(AuctionMailer, winner_notification: mailer,
                             seller_auction_completed: mailer,
                             seller_auction_no_winner: mailer)
  end
  let(:notifier_job) { class_spy(ExternalSystemNotifierJob) }

  before do
    stub_const('AuctionMailer', auction_mailer)
    stub_const('ExternalSystemNotifierJob', notifier_job)
  end

  describe '#perform' do
    context 'when auction has a winning bid' do
      let!(:winning_bid) { create(:bid, auction: auction, user: bidder, amount: 100) }

      it 'completes the auction with the winning bid' do
        expect do
          perform_enqueued_jobs { described_class.perform_later(auction.id) }
        end.to change { auction.reload.completed? }.from(false).to(true)
           .and change(auction, :winning_bid_id).to(winning_bid.id)
      end

      it 'sends winner notification' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }

        expect(auction_mailer).to have_received(:winner_notification)
          .with(bidder, auction)
      end

      it 'sends seller completion notification' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }

        expect(auction_mailer).to have_received(:seller_auction_completed)
          .with(seller, auction, winning_bid)
      end

      it 'notifies external system' do
        completion_time = Time.current
        allow(Time).to receive(:current).and_return(completion_time)

        perform_enqueued_jobs { described_class.perform_later(auction.id) }

        expect(notifier_job).to have_received(:perform_later)
          .with(
            event: 'auction_completed',
            auction_id: auction.id,
            winner_id: bidder.id,
            winning_amount: winning_bid.amount,
            completed_at: completion_time
          )
      end
    end

    context 'when auction has no bids' do
      it 'completes the auction without a winning bid' do
        expect do
          perform_enqueued_jobs { described_class.perform_later(auction.id) }
        end.to change { auction.reload.completed? }.from(false).to(true)
      end

      it 'notifies seller about no winner' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }

        expect(auction_mailer).to have_received(:seller_auction_no_winner)
          .with(seller, auction)
      end

      it 'notifies external system about no winner' do
        completion_time = Time.current
        allow(Time).to receive(:current).and_return(completion_time)

        perform_enqueued_jobs { described_class.perform_later(auction.id) }

        expect(notifier_job).to have_received(:perform_later)
          .with(
            event: 'auction_completed',
            auction_id: auction.id,
            winner_id: nil,
            winning_amount: nil,
            completed_at: completion_time
          )
      end
    end

    context 'when auction is already completed' do
      before { auction.update!(completed_at: Time.current) }

      it 'does not send winner notification' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }
        expect(auction_mailer).not_to have_received(:winner_notification)
      end

      it 'does not send seller completion notification' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }
        expect(auction_mailer).not_to have_received(:seller_auction_completed)
      end

      it 'does not send no-winner notification' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }
        expect(auction_mailer).not_to have_received(:seller_auction_no_winner)
      end

      it 'does not notify external system' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }
        expect(notifier_job).not_to have_received(:perform_later)
      end
    end

    context 'when auction has not ended yet' do
      let(:auction) { create(:auction, seller: seller, ends_at: 1.hour.from_now) }

      it 'does not process the auction' do
        perform_enqueued_jobs { described_class.perform_later(auction.id) }

        aggregate_failures do
          expect(auction_mailer).not_to have_received(:winner_notification)
          expect(auction_mailer).not_to have_received(:seller_auction_completed)
          expect(auction_mailer).not_to have_received(:seller_auction_no_winner)
          expect(notifier_job).not_to have_received(:perform_later)
        end
      end
    end
  end
end
