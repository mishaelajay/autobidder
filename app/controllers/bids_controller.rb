# frozen_string_literal: true

# Controller responsible for managing auction bids.
# Handles bid creation and viewing bid history.
class BidsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_auction, only: [:create]

  def index
    @bids = fetch_user_bids
  end

  def create
    @bid = @auction.bids.build(bid_params)
    @bid.user = current_user

    # Use transaction to ensure data consistency
    ActiveRecord::Base.transaction do
      if @bid.save
        handle_successful_bid
      else
        handle_failed_bid
      end
    end
  end

  private

  def set_auction
    @auction = Auction.select(:id, :seller_id, :starting_price, :minimum_selling_price, :ends_at, :completed_at)
                      .lock('FOR UPDATE') # Lock the auction record to prevent race conditions
                      .find(params[:auction_id])
  end

  def build_bid
    current_user.bids.build(
      bid_params.merge(auction: @auction)
    )
  end

  def can_place_bid?
    return false if @auction.seller == current_user
    return false if @auction.ended?

    true
  end

  def handle_successful_bid
    AutoBidProcessor.new(@auction).process
    respond_to_successful_bid
  end

  def handle_failed_bid
    respond_to_failed_bid
  end

  def respond_to_successful_bid
    respond_to do |format|
      format.html { redirect_to @auction, notice: t('.success') }
      format.turbo_stream { head :ok }
    end
  end

  def respond_to_failed_bid
    respond_to do |format|
      format.html { redirect_to @auction, alert: @bid.errors.full_messages.to_sentence }
      format.turbo_stream { flash.now[:alert] = @bid.errors.full_messages.to_sentence }
    end
  end

  def render_turbo_stream_response
    render turbo_stream: [
      turbo_stream.update('flash_messages', partial: 'shared/flash_messages'),
      turbo_stream.replace("auction_#{@auction.id}_bid_actions",
                           partial: 'auctions/bid_actions',
                           locals: { auction: @auction }),
      turbo_stream.prepend("auction_#{@auction.id}_bids",
                           partial: 'bids/bid',
                           locals: { bid: @bid })
    ]
  end

  def bid_params
    params.require(:bid).permit(:amount)
  end

  def fetch_user_bids
    current_user.bids
                .joins(:auction)
                .includes(:auction)
                .select(bid_select_fields)
                .order('bids.created_at DESC')
                .page(params[:page])
  end

  def bid_select_fields
    [
      'bids.id',
      'bids.amount',
      'bids.created_at',
      'bids.auction_id',
      'auctions.title as auction_title'
    ]
  end
end
