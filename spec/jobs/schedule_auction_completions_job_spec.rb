require 'rails_helper'

RSpec.describe ScheduleAuctionCompletionsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform' do
    let!(:ended_uncompleted_auction) { 
      create(:auction, ends_at: 1.hour.ago, completed_at: nil) 
    }
    let!(:ended_completed_auction) { 
      create(:auction, ends_at: 1.hour.ago, completed_at: Time.current) 
    }
    let!(:future_auction) { 
      create(:auction, ends_at: 1.hour.from_now) 
    }
    let!(:ended_with_winner) {
      auction = create(:auction, ends_at: 1.hour.ago)
      create(:bid, auction: auction)
      auction.update!(winning_bid: auction.bids.first)
      auction
    }

    before do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'schedules completion for ended uncompleted auctions' do
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to have_enqueued_job(CompleteAuctionJob)
        .with(ended_uncompleted_auction.id)
    end

    it 'does not schedule completion for completed auctions' do
      perform_enqueued_jobs { described_class.perform_later }
      
      expect(CompleteAuctionJob).not_to have_been_enqueued
        .with(ended_completed_auction.id)
    end

    it 'does not schedule completion for future auctions' do
      perform_enqueued_jobs { described_class.perform_later }
      
      expect(CompleteAuctionJob).not_to have_been_enqueued
        .with(future_auction.id)
    end

    it 'does not schedule completion for auctions with winners' do
      perform_enqueued_jobs { described_class.perform_later }
      
      expect(CompleteAuctionJob).not_to have_been_enqueued
        .with(ended_with_winner.id)
    end

    it 'schedules itself to run again in 5 minutes' do
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to have_enqueued_job(described_class).at(5.minutes.from_now)
    end
  end
end 