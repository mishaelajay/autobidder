# frozen_string_literal: true

# Controller responsible for managing automatic bidding settings.
# Handles creation and management of auto-bid configurations for users.
class AutoBidsController < ApplicationController
  before_action :set_auction

  def create
    @auto_bid = @auction.auto_bids.build(auto_bid_params)
    @auto_bid.user = current_user

    if @auto_bid.save
      AutoBidProcessor.new(@auction).process
      redirect_to @auction, notice: t('.success')
    else
      redirect_to @auction, alert: @auto_bid.errors.full_messages.to_sentence
    end
  end

  def destroy
    @auto_bid = current_user.auto_bids.find_by!(auction: @auction)
    @auto_bid.destroy
    redirect_to @auction, notice: t('.success')
  end

  private

  def set_auction
    @auction = Auction.find(params[:auction_id])
  end

  def auto_bid_params
    params.require(:auto_bid).permit(:maximum_amount)
  end
end
