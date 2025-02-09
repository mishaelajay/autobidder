# frozen_string_literal: true

FactoryBot.define do
  factory :auto_bid do
    user
    auction

    # Set maximum_amount to be higher than auction's current price
    maximum_amount do
      current_price = auction.current_price
      current_price + 100 # Add a buffer to ensure it's higher than current price
    end
  end
end
