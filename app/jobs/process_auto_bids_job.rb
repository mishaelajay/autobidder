# frozen_string_literal: true

# Background job responsible for processing automatic bids.
# Handles the execution of auto-bids based on user configurations and auction status.
class ProcessAutoBidsJob < ApplicationJob
  queue_as :default

  def perform(auction_id)
    auction = Auction.find(auction_id)
    return unless auction.active?

    AutoBidProcessor.new(auction).process
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Auction #{auction_id} not found: #{e.message}"
  end
end
