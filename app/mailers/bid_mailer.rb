# frozen_string_literal: true

# Mailer responsible for sending bid-related email notifications.
# Handles notifications for bid placement, winning bids, and auction completion.
class BidMailer < ApplicationMailer
  def outbid_notification(user, auction)
    @user = user
    @auction = auction
    @current_price = auction.current_price

    mail(
      to: @user.email,
      subject: "You've been outbid on #{@auction.title}"
    )
  end
end
