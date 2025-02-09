# AutoBidder

AutoBidder is a real-time auction platform built with Ruby on Rails that supports manual and automatic bidding. Users can create auctions, place manual bids, and set up auto-bidding with maximum amounts.

## Features

- User authentication with Devise
- Real-time updates using Hotwire/Turbo
- Manual bidding system
- Automatic bidding system
- Auction completion handling
- Email notifications
- Background job processing with Sidekiq
- Modern UI with Tailwind CSS

## Requirements

- Ruby 3.2.4
- Rails 7.1.4
- SQLite3
- Redis (for Sidekiq and Action Cable)
- Node.js and Yarn (for asset compilation)

## Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/autobidder.git
cd autobidder
```

2. Install dependencies:
```bash
bundle install
yarn install
```

3. Setup the database:
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Start Redis server:
```bash
redis-server
```

5. Start Sidekiq:
```bash
bundle exec sidekiq
```

6. Precompile assets:
```bash
rails assets:clobber && rails assets:precompile
```

7. Start the Rails server:
```bash
rails s
```

The application will be available at http://localhost:3000

## Test Users

After running `rails db:seed`, the following test users will be available:

```ruby
# Seller Account
Email: seller@example.com
Password: password123

# Bidder Accounts
Email: bidder1@example.com
Password: password123

Email: bidder2@example.com
Password: password123
```

## Testing the Bidding System

1. Login as the seller (seller@example.com) and create a new auction:
   - Click "New Auction" in the navigation
   - Fill in the auction details (title, description, starting price, etc.)
   - Set an end time in the future

2. Login as a bidder (bidder1@example.com) and place bids:
   - Manual Bidding:
     - Visit an active auction
     - Use the "Quick Bid" button for the minimum next bid amount
     - Or enter a custom amount in the bid form

   - Auto Bidding:
     - Set a maximum amount in the "Auto Bidding" section
     - The system will automatically place bids up to this amount when outbid

3. Login as another bidder (bidder2@example.com) to test competitive bidding:
   - Place competing bids to see the auto-bidding system in action
   - Watch real-time updates as bids are placed

## Development

### Running Tests

```bash
bundle exec rspec
```

### Background Jobs

The application uses Sidekiq for processing background jobs:

- Auction completion
- Email notifications
- Auto-bid processing

Monitor background jobs at http://localhost:3000/sidekiq (requires authentication)

### Email Delivery

In development, emails are caught by the `letter_opener` gem and can be viewed in the browser.
I have disabled letter_opener since it can get quite annoying when an autobid is outbidding you. You can enable the same to see the emails.

## Future Developments

### Performance Optimizations
1. **Database Efficiency**
   - Implement database partitioning for completed auctions to improve query performance
   - Add materialized views for frequently accessed auction statistics
   - Implement database cleanup jobs for old/completed auctions

2. **Caching Strategy**
   - Implement Redis caching for auction current prices and bid counts
   - Add fragment caching for auction listings and bid history
   - Cache user bid statistics and auction participation data

3. **Background Processing**
   - Move email notifications to batch processing for outbid notifications
   - Implement rate limiting for auto-bidding to prevent system overload
   - Add queue prioritization for critical jobs (e.g., auction completion)

4. **Real-time Updates**
   - Optimize WebSocket connections using connection pooling
   - Implement batch updates for multiple simultaneous bids
   - Add client-side state management to reduce server requests

5. **Auto-bidding Improvements**
   - Implement batched bid processing for multiple auto-bids
   - Add smart bid increment calculations based on auction activity
   - Optimize locking strategy for high-concurrency auctions

6. **Monitoring and Scaling**
   - Add performance monitoring for auto-bidding system
   - Implement horizontal scaling for bid processors
   - Add automatic cleanup for stale/abandoned auto-bids

### Security Enhancements
1. **Rate Limiting**
   - Add bid rate limiting per user
   - Implement IP-based rate limiting for auction views
   - Add fraud detection for suspicious bidding patterns

2. **Authentication**
   - Add two-factor authentication for high-value auctions
   - Implement OAuth support for social login
   - Add session management improvements

### User Experience
1. **Notifications**
   - Add real-time push notifications
   - Implement SMS notifications for important events
   - Add customizable notification preferences

2. **Bidding Interface**
   - Add bid scheduling for future times
   - Implement bid suggestions based on history
   - Add auction analytics for sellers

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.
