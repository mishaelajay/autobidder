# frozen_string_literal: true

require 'sidekiq-scheduler'

# Schedule the auction completion check to run every 5 minutes
Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq.schedule = {
      'schedule_auction_completions' => {
        'class' => 'ScheduleAuctionCompletionsJob',
        'cron' => '*/5 * * * *' # Every 5 minutes
      }
    }
  end
end
