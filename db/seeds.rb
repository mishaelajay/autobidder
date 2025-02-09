# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create test users
Rails.logger.debug 'Creating users...'

seller = User.create!(
  email: 'seller@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Test Seller'
)

bidder1 = User.create!(
  email: 'bidder1@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Test Bidder 1'
)

bidder2 = User.create!(
  email: 'bidder2@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Test Bidder 2'
)

Rails.logger.debug 'Creating auctions...'

# Create active auctions
3.times do |i|
  auction = Auction.create!(
    seller: seller,
    title: "Active Auction #{i + 1}",
    description: 'This is a test auction with some interesting items up for bidding.',
    starting_price: rand(10..50),
    minimum_selling_price: rand(100..500),
    ends_at: rand(1..7).days.from_now
  )

  Rails.logger.debug { "Created auction: #{auction.title}" }

  # Add some initial bids
  next unless rand > 0.5

  Bid.create!(
    user: bidder1,
    auction: auction,
    amount: auction.starting_price + rand(10..20)
  )

  next unless rand > 0.5

  Bid.create!(
    user: bidder2,
    auction: auction,
    amount: auction.current_price + rand(10..20)
  )
end

# Create an auction that's ending soon
ending_soon = Auction.create!(
  seller: seller,
  title: 'Ending Soon Auction',
  description: 'Quick! This auction is ending very soon!',
  starting_price: 25.00,
  minimum_selling_price: 100.00,
  ends_at: 30.minutes.from_now
)

Rails.logger.debug { "Created auction: #{ending_soon.title}" }

# Create some bids on the ending soon auction
Bid.create!(
  user: bidder1,
  auction: ending_soon,
  amount: 35.00
)

Bid.create!(
  user: bidder2,
  auction: ending_soon,
  amount: 45.00
)

# Set up an auto bid for testing
AutoBid.create!(
  user: bidder1,
  auction: ending_soon,
  maximum_amount: 75.00
)

Rails.logger.debug "\nSeeding completed!"
Rails.logger.debug 'Test accounts created:'
Rails.logger.debug 'Seller: seller@example.com / password123'
Rails.logger.debug 'Bidder 1: bidder1@example.com / password123'
Rails.logger.debug 'Bidder 2: bidder2@example.com / password123'
Rails.logger.debug { "\nCreated #{Auction.count} auctions" }
Rails.logger.debug { "Created #{Bid.count} bids" }
Rails.logger.debug { "Created #{AutoBid.count} auto bids" }
