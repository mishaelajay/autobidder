FactoryBot.define do
  factory :auto_bid do
    association :user
    association :auction
    
    # Set maximum_amount to be higher than auction's current price
    maximum_amount { auction.current_price + 100 }
  end
end 