FactoryBot.define do
  factory :bid do
    association :user
    association :auction
    
    amount { auction.minimum_next_bid }

    trait :for_ended_auction do
      # Skip validation when creating bids for ended auctions
      to_create { |instance| instance.save(validate: false) }
    end

    trait :winning do
      amount { 1000.00 }
      after(:create) do |bid|
        bid.auction.update!(winning_bid: bid)
      end
    end
  end
end 