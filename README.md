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

## Production Deployment

Additional steps for production deployment:

1. Set up proper database (PostgreSQL recommended)
2. Configure environment variables:
   ```
   REDIS_URL=redis://your-redis-url
   DATABASE_URL=postgres://your-database-url
   RAILS_MASTER_KEY=your-master-key
   ```
3. Set up proper email delivery service
4. Configure SSL/TLS
5. Set up proper background job processing

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE.md file for details
