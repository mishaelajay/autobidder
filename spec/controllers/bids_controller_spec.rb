require 'rails_helper'

RSpec.describe BidsController, type: :controller do
  let(:user) { create(:user) }
  let(:auction) { create(:auction) }

  before do
    sign_in user
  end

  describe 'GET #index' do
    let!(:bids) { create_list(:bid, 3, user: user) }
    let!(:other_user_bids) { create_list(:bid, 2, user: create(:user)) }

    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns @bids with current user bids' do
      get :index
      expect(assigns(:bids)).to match_array(bids)
    end

    it 'does not include other users bids' do
      get :index
      expect(assigns(:bids)).not_to include(other_user_bids)
    end

    it 'orders bids by created_at desc' do
      get :index
      expect(assigns(:bids)).to eq(bids.sort_by(&:created_at).reverse)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) { { amount: auction.minimum_next_bid } }
    let(:invalid_attributes) { { amount: 0 } }

    context 'with valid params' do
      it 'creates a new bid' do
        expect {
          post :create, params: { auction_id: auction.id, bid: valid_attributes }
        }.to change(Bid, :count).by(1)
      end

      it 'assigns the current user to the bid' do
        post :create, params: { auction_id: auction.id, bid: valid_attributes }
        expect(Bid.last.user).to eq(user)
      end

      it 'redirects to the auction' do
        post :create, params: { auction_id: auction.id, bid: valid_attributes }
        expect(response).to redirect_to(auction)
      end

      it 'sets a success notice' do
        post :create, params: { auction_id: auction.id, bid: valid_attributes }
        expect(flash[:notice]).to eq('Bid was successfully placed.')
      end
    end

    context 'with invalid params' do
      it 'does not create a new bid' do
        expect {
          post :create, params: { auction_id: auction.id, bid: invalid_attributes }
        }.not_to change(Bid, :count)
      end

      it 'redirects to the auction with an error message' do
        post :create, params: { auction_id: auction.id, bid: invalid_attributes }
        expect(response).to redirect_to(auction)
        expect(flash[:alert]).to be_present
      end
    end

    context 'with turbo_stream format' do
      it 'returns success status for valid bid' do
        post :create, params: { auction_id: auction.id, bid: valid_attributes }, format: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
    end
  end
end 