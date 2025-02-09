# frozen_string_literal: true

FactoryBot.define do
  factory :auction do
    seller factory: %i[user]

    sequence(:title) { |n| "Auction #{n}" }
    description { 'A detailed description of the item' }
    starting_price { 10.00 }
    minimum_selling_price { 100.00 }
    ends_at { 1.week.from_now }

    trait :active do
      ends_at { 1.week.from_now }
    end

    trait :ended do
      transient do
        ended_at { 1.day.ago }
      end

      ends_at { ended_at }

      after(:build) do |auction, evaluator|
        auction.ends_at = evaluator.ended_at
      end

      to_create do |instance|
        instance.save(validate: false)
      end
    end

    trait :with_bids do
      after(:create) do |auction|
        create_list(:bid, 3, auction: auction)
      end
    end

    trait :completed do
      ended

      after(:create) do |auction|
        winning_bid = create(:bid, :for_ended_auction, auction: auction)
        auction.update!(winning_bid: winning_bid, completed_at: Time.current)
      end
    end

    # Factory method to create an auction that has already ended
    factory :ended_auction do
      ended
    end
  end
end
