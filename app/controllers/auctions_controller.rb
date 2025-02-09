# frozen_string_literal: true

class AuctionsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_auction, only: %i[show edit update destroy]
  before_action :authorize_seller!, only: %i[edit update destroy]

  def index
    @auctions = if params[:filter] == 'mine' && current_user
                  current_user.auctions
                else
                  Auction.active
                end

    @auctions = @auctions.order(ends_at: :asc)
  end

  def show
    @bid = Bid.new
    @auto_bid = AutoBid.new
  end

  def new
    @auction = Auction.new
  end

  def edit; end

  def create
    @auction = current_user.auctions.build(auction_params)

    if @auction.save
      redirect_to @auction, notice: 'Auction was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @auction.update(auction_params)
      redirect_to @auction, notice: 'Auction was successfully updated.'
    else
      render :edit, status: :ok
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

  def authorize_seller!
    return if @auction.seller == current_user

    redirect_to auctions_path, alert: 'You are not authorized to perform this action.'
  end

  def auction_params
    params.require(:auction).permit(:title, :description, :starting_price,
                                    :minimum_selling_price, :ends_at)
  end
end
