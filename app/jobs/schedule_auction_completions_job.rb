# frozen_string_literal: true

# Background job responsible for scheduling auction completion jobs.
# Identifies auctions that need to be completed and schedules their completion process.
class ScheduleAuctionCompletionsJob < ApplicationJob
  queue_as :default

  def perform
    # Find all auctions that:
    # 1. Have ended
    # 2. Haven't been completed yet
    # 3. Don't have a winning bid set
    pending_auctions = Auction
                       .where(ends_at: ..Time.current)
                       .where(completed_at: nil)
                       .where(winning_bid_id: nil)

    pending_auctions.find_each do |auction|
      # Schedule immediate completion
      CompleteAuctionJob.perform_later(auction.id)
    end

    # Schedule next run in 5 minutes
    self.class.set(wait: 5.minutes).perform_later
  end
end
