# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BidsController, type: :controller do
  let(:user) { create(:user) }
  let(:seller) { create(:user) }
  let(:auction) { create(:auction, seller: seller, starting_price: 100) }

  describe 'GET #index' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      let!(:user_bids) { create_list(:bid, 3, user: user) }
      let!(:other_bids) { create_list(:bid, 2, user: create(:user)) }

      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns @bids with only the user bids' do
        get :index
        expect(assigns(:bids)).to match_array(user_bids)
      end

      it 'orders bids by created_at desc' do
        get :index
        expect(assigns(:bids)).to eq(user_bids.sort_by(&:created_at).reverse)
      end

      it 'paginates results' do
        create_list(:bid, 30, user: user)
        get :index
        expect(assigns(:bids).size).to eq(25) # default per_page
      end
    end
  end

  describe 'POST #create' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        post :create, params: { auction_id: auction.id, bid: { amount: 150 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'with valid params' do
        let(:valid_params) { { auction_id: auction.id, bid: { amount: 150 } } }

        it 'creates a new bid' do
          expect do
            post :create, params: valid_params
          end.to change(Bid, :count).by(1)
        end

        it 'assigns the current user to the bid' do
          post :create, params: valid_params
          expect(Bid.last.user).to eq(user)
        end

        it 'redirects to the auction with HTML format' do
          post :create, params: valid_params
          expect(response).to redirect_to(auction)
        end

        it 'sets a success notice with HTML format' do
          post :create, params: valid_params
          expect(flash[:notice]).to eq('Bid was successfully placed.')
        end

        it 'returns success with Turbo Stream format' do
          post :create, params: valid_params, format: :turbo_stream
          expect(response).to be_successful
        end

        it 'triggers auto bid processing' do
          expect_any_instance_of(AutoBidProcessor).to receive(:process)
          post :create, params: valid_params
        end
      end

      context 'with invalid params' do
        let(:invalid_params) { { auction_id: auction.id, bid: { amount: 0 } } }

        it 'does not create a new bid' do
          expect do
            post :create, params: invalid_params
          end.not_to change(Bid, :count)
        end

        it 'redirects to auction with error message in HTML format' do
          post :create, params: invalid_params
          expect(response).to redirect_to(auction)
          expect(flash[:alert]).to be_present
        end

        it 'returns unprocessable entity status with Turbo Stream format' do
          post :create, params: invalid_params, format: :turbo_stream
          expect(response).to be_successful
          expect(flash.now[:alert]).to be_present
        end
      end

      context 'when bidding on own auction' do
        let(:own_auction) { create(:auction, seller: user) }

        it 'does not create a bid' do
          expect do
            post :create, params: { auction_id: own_auction.id, bid: { amount: 150 } }
          end.not_to change(Bid, :count)
        end

        it 'sets an error message' do
          post :create, params: { auction_id: own_auction.id, bid: { amount: 150 } }
          expect(flash[:alert]).to include('Cannot bid on your own auction')
        end
      end

      context 'when auction has ended' do
        let(:ended_auction) { create(:auction, :ended, seller: seller) }

        it 'does not create a bid' do
          expect do
            post :create, params: { auction_id: ended_auction.id, bid: { amount: 150 } }
          end.not_to change(Bid, :count)
        end

        it 'sets an error message' do
          post :create, params: { auction_id: ended_auction.id, bid: { amount: 150 } }
          expect(flash[:alert]).to include('Cannot bid on ended auction')
        end
      end
    end
  end
end
