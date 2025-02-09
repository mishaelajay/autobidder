class AuctionsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_auction, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]

  def index
    @auctions = if params[:filter] == 'mine' && user_signed_in?
      current_user.auctions.order(created_at: :desc)
    else
      Auction.active.order(ends_at: :asc)
    end
  end

  def show
    @bid = Bid.new
    @auto_bid = AutoBid.new
  end

  def new
    @auction = Auction.new
  end

  def create
    @auction = current_user.auctions.build(auction_params)
    if @auction.save
      redirect_to @auction, notice: 'Auction was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @auction.update(auction_params)
      redirect_to @auction, notice: 'Auction was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @auction.destroy
    redirect_to auctions_url, notice: 'Auction was successfully destroyed.'
  end

  private

  def set_auction
    @auction = Auction.find(params[:id])
  end

  def ensure_owner
    unless @auction.seller == current_user
      redirect_to auctions_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def auction_params
    params.require(:auction).permit(:title, :description, :starting_price, 
                                  :minimum_selling_price, :ends_at)
  end
end 