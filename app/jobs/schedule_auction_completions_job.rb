# frozen_string_literal: true

# Background job responsible for scheduling auction completion jobs.
# Identifies auctions that need to be completed and schedules their completion process.
class ScheduleAuctionCompletionsJob < ApplicationJob
  queue_as :default

  def perform(schedule_next: true)
    schedule_pending_auction_completions
    schedule_next_run if schedule_next
  end

  private

  def schedule_pending_auction_completions
    pending_auctions.find_each do |auction|
      CompleteAuctionJob.perform_later(auction.id)
    end
  end

  def pending_auctions
    Auction
      .where(ends_at: ..Time.current)
      .where(completed_at: nil)
      .where(winning_bid_id: nil)
  end

  def schedule_next_run
    self.class.set(wait: 5.minutes).perform_later(schedule_next: true)
  end
end
