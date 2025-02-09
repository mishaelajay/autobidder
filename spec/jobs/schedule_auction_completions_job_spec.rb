# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScheduleAuctionCompletionsJob do
  include ActiveJob::TestHelper

  describe '#perform' do
    let!(:ended_uncompleted_auction) do
      create(:auction, :ended)
    end
    let!(:ended_completed_auction) do
      create(:auction, :ended, completed_at: Time.current)
    end
    let!(:future_auction) do
      create(:auction, :active)
    end
    let!(:ended_with_winner) do
      create(:auction, :completed)
    end

    before do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'schedules completion for ended uncompleted auctions' do
      described_class.perform_now

      expect(CompleteAuctionJob)
        .to have_been_enqueued
        .with(ended_uncompleted_auction.id)
    end

    it 'does not schedule completion for completed auctions' do
      described_class.perform_now

      expect(CompleteAuctionJob)
        .not_to have_been_enqueued
        .with(ended_completed_auction.id)
    end

    it 'does not schedule completion for future auctions' do
      described_class.perform_now

      expect(CompleteAuctionJob)
        .not_to have_been_enqueued
        .with(future_auction.id)
    end

    it 'does not schedule completion for auctions with winners' do
      described_class.perform_now

      expect(CompleteAuctionJob)
        .not_to have_been_enqueued
        .with(ended_with_winner.id)
    end

    it 'schedules itself to run again in 5 minutes' do
      freeze_time do
        described_class.perform_now(schedule_next: true)

        expect(described_class)
          .to have_been_enqueued
          .with(schedule_next: true)
          .at(5.minutes.from_now)
      end
    end
  end
end
