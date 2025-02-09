# frozen_string_literal: true

# Mailer responsible for sending auction-related email notifications.
# Handles notifications for auction completion, winning bids, and seller updates.
class AuctionMailer < ApplicationMailer
  def winner_notification(user, auction)
    @user = user
    @auction = auction
    mail(to: @user.email, subject: "You won the auction for #{@auction.title}!")
  end

  def seller_auction_completed(seller, auction, winning_bid)
    @seller = seller
    @auction = auction
    @winning_bid = winning_bid
    mail(to: @seller.email, subject: "Your auction #{@auction.title} has completed with a winner!")
  end

  def seller_auction_no_winner(seller, auction)
    @seller = seller
    @auction = auction
    mail(to: @seller.email, subject: "Your auction #{@auction.title} has ended without a winner")
  end

  def auction_lost_notification(auction, bidder)
    @auction = auction
    @bidder = bidder
    mail(to: @bidder.email, subject: "Auction #{@auction.title} has ended - you were outbid")
  end
end 