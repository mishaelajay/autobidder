# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create a test user
User.find_or_create_by!(
  email: 'test@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Test User'
)

puts "Test user created:"
puts "Email: test@example.com"
puts "Password: password123"

# Add this to your seeds.rb
User.create!(
  email: 'bidder@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Test Bidder'
)

# Create a sample auction
test_user = User.find_by(email: 'test@example.com')
Auction.create!(
  seller: test_user,
  title: 'Test Auction',
  description: 'This is a test auction',
  starting_price: 10.00,
  minimum_selling_price: 50.00,
  ends_at: 24.hours.from_now
)
