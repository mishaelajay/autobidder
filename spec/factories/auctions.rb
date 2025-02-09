# frozen_string_literal: true

FactoryBot.define do
  factory :auction do
    seller factory: %i[user]

    sequence(:title) { |n| "Auction #{n}" }
    description { 'A detailed description of the item' }
    starting_price { 10.00 }
    minimum_selling_price { 100.00 }
    ends_at { 1.week.from_now }

    trait :ended do
      # Skip validation when creating ended auctions
      to_create { |instance| instance.save(validate: false) }
      ends_at { 1.day.ago }
    end

    trait :with_bids do
      after(:create) do |auction|
        create_list(:bid, 3, auction: auction)
      end
    end

    trait :completed do
      ended
      completed_at { Time.current }

      after(:create) do |auction|
        winning_bid = create(:bid, auction: auction)
        auction.update!(winning_bid: winning_bid)
      end
    end

    # Factory method to create an auction that has already ended
    factory :ended_auction do
      to_create { |instance| instance.save(validate: false) }
      ends_at { 1.day.ago }
    end
  end
end
