# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Only run in production and if the server is not console or rake
  if Rails.env.production? && !defined?(Rails::Console) && !defined?(Rails::Generators) && !Rails.env.test?
    # Schedule the job to run immediately
    ScheduleAuctionCompletionsJob.perform_later
  end
end
