# frozen_string_literal: true

FactoryBot.define do
  factory :auto_bid do
    user
    auction

    # Set maximum_amount to be higher than auction's current price
    maximum_amount { auction.current_price + 100 }
  end
end
