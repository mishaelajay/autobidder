# frozen_string_literal: true

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
