class BidsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_auction, only: [:create]

  def index
    @bids = current_user.bids
      .joins(:auction)
      .includes(:auction)  # Keep the eager loading for auction associations
      .select(
        'bids.id',
        'bids.amount',
        'bids.created_at',
        'bids.auction_id',
        'auctions.title as auction_title'
      )
      .order('bids.created_at DESC')
      .page(params[:page])
  end

  def create
    @bid = @auction.bids.build(bid_params)
    @bid.user = current_user

    # Use transaction to ensure data consistency
    ActiveRecord::Base.transaction do
      if @bid.save
        respond_to do |format|
          format.html { redirect_to @auction, notice: 'Bid was successfully placed.' }
          format.turbo_stream { head :ok }
        end
      else
        redirect_to @auction, alert: @bid.errors.full_messages.to_sentence
      end
    end
  end

  private

  def set_auction
    @auction = Auction.select(:id, :seller_id, :starting_price, :minimum_selling_price, :ends_at)
      .lock("FOR UPDATE")  # Lock the auction record to prevent race conditions
      .find(params[:auction_id])
  end

  def bid_params
    params.require(:bid).permit(:amount)
  end
end 