# frozen_string_literal: true

namespace :auctions do
  desc 'Complete a specific auction'
  task :complete, [:auction_id] => :environment do |_t, args|
    if args[:auction_id].blank?
      puts 'Usage: rake auctions:complete[auction_id]'
      exit 1
    end

    auction = Auction.find(args[:auction_id])
    if auction.completed?
      puts "Auction #{auction.id} is already completed"
    else
      CompleteAuctionJob.perform_now(auction.id)
      puts "Auction #{auction.id} completion processed"
    end
  end

  desc 'Schedule completion for all ended but uncompleted auctions'
  task schedule_completions: :environment do
    auctions = Auction
               .where(ends_at: ..Time.current)
               .where(completed_at: nil)
               .where(winning_bid_id: nil)

    puts "Found #{auctions.count} auctions to complete"

    auctions.find_each do |auction|
      CompleteAuctionJob.perform_later(auction.id)
      puts "Scheduled completion for auction #{auction.id}"
    end
  end
end
