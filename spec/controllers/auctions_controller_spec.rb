# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuctionsController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      title: 'Test Auction',
      description: 'A test auction description',
      starting_price: 100,
      minimum_selling_price: 200,
      ends_at: 1.week.from_now
    }
  end

  let(:invalid_attributes) do
    {
      title: '',
      description: '',
      starting_price: -1,
      minimum_selling_price: -1,
      ends_at: 1.day.ago
    }
  end

  describe 'GET #index' do
    let!(:active_auction) { create(:auction, ends_at: 1.week.from_now) }
    let!(:ended_auction) { create(:auction, :ended) }

    context 'without filter' do
      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns only active auctions to @auctions' do
        get :index
        expect(assigns(:auctions)).to include(active_auction)
        expect(assigns(:auctions)).not_to include(ended_auction)
      end

      it 'orders auctions by ends_at asc' do
        auction1 = create(:auction, ends_at: 2.days.from_now)
        auction2 = create(:auction, ends_at: 1.day.from_now)
        get :index
        expect(assigns(:auctions)).to eq([auction2, auction1, active_auction])
      end
    end

    context 'with mine filter' do
      before { sign_in user }

      let!(:user_auction) { create(:auction, seller: user) }
      let!(:other_auction) { create(:auction, seller: create(:user)) }

      it 'assigns only user auctions to @auctions when filtered' do
        get :index, params: { filter: 'mine' }
        expect(assigns(:auctions)).to include(user_auction)
        expect(assigns(:auctions)).not_to include(other_auction)
      end
    end
  end

  describe 'GET #show' do
    let(:auction) { create(:auction) }

    it 'returns a successful response' do
      get :show, params: { id: auction.id }
      expect(response).to be_successful
    end

    it 'assigns the requested auction to @auction' do
      get :show, params: { id: auction.id }
      expect(assigns(:auction)).to eq(auction)
    end

    it 'initializes a new bid' do
      get :show, params: { id: auction.id }
      expect(assigns(:bid)).to be_a_new(Bid)
    end

    it 'initializes a new auto bid' do
      get :show, params: { id: auction.id }
      expect(assigns(:auto_bid)).to be_a_new(AutoBid)
    end
  end

  describe 'GET #new' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      it 'returns a successful response' do
        get :new
        expect(response).to be_successful
      end

      it 'assigns a new auction to @auction' do
        get :new
        expect(assigns(:auction)).to be_a_new(Auction)
      end
    end
  end

  describe 'POST #create' do
    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        post :create, params: { auction: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'with valid params' do
        it 'creates a new auction' do
          expect do
            post :create, params: { auction: valid_attributes }
          end.to change(Auction, :count).by(1)
        end

        it 'assigns the current user as the seller' do
          post :create, params: { auction: valid_attributes }
          expect(Auction.last.seller).to eq(user)
        end

        it 'redirects to the created auction' do
          post :create, params: { auction: valid_attributes }
          expect(response).to redirect_to(Auction.last)
        end

        it 'sets a success notice' do
          post :create, params: { auction: valid_attributes }
          expect(flash[:notice]).to eq('Auction was successfully created.')
        end
      end

      context 'with invalid params' do
        it 'does not create a new auction' do
          expect do
            post :create, params: { auction: invalid_attributes }
          end.not_to change(Auction, :count)
        end

        it 'returns unprocessable entity status' do
          post :create, params: { auction: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET #edit' do
    let(:auction) { create(:auction, seller: user) }

    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        get :edit, params: { id: auction.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'when user is the seller' do
        it 'returns a successful response' do
          get :edit, params: { id: auction.id }
          expect(response).to be_successful
        end
      end

      context 'when user is not the seller' do
        let(:other_auction) { create(:auction, seller: create(:user)) }

        it 'redirects to auctions path' do
          get :edit, params: { id: other_auction.id }
          expect(response).to redirect_to(auctions_path)
        end

        it 'sets an alert message' do
          get :edit, params: { id: other_auction.id }
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:auction) { create(:auction, seller: user) }
    let(:new_attributes) { { title: 'Updated Title' } }

    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        patch :update, params: { id: auction.id, auction: new_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'when user is the seller' do
        context 'with valid params' do
          it 'updates the requested auction' do
            patch :update, params: { id: auction.id, auction: new_attributes }
            auction.reload
            expect(auction.title).to eq('Updated Title')
          end

          it 'redirects to the auction' do
            patch :update, params: { id: auction.id, auction: new_attributes }
            expect(response).to redirect_to(auction)
          end

          it 'sets a success notice' do
            patch :update, params: { id: auction.id, auction: new_attributes }
            expect(flash[:notice]).to eq('Auction was successfully updated.')
          end
        end

        context 'with invalid params' do
          it 'returns a success response (i.e. to display the edit template)' do
            patch :update, params: { id: auction.id, auction: invalid_attributes }
            expect(response).to be_successful
          end
        end
      end

      context 'when user is not the seller' do
        let(:other_auction) { create(:auction, seller: create(:user)) }

        it 'redirects to auctions path' do
          patch :update, params: { id: other_auction.id, auction: new_attributes }
          expect(response).to redirect_to(auctions_path)
        end

        it 'sets an alert message' do
          patch :update, params: { id: other_auction.id, auction: new_attributes }
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:auction) { create(:auction, seller: user) }

    context 'when user is not signed in' do
      it 'redirects to sign in page' do
        delete :destroy, params: { id: auction.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      before { sign_in user }

      context 'when user is the seller' do
        it 'destroys the requested auction' do
          expect do
            delete :destroy, params: { id: auction.id }
          end.to change(Auction, :count).by(-1)
        end

        it 'redirects to the auctions list' do
          delete :destroy, params: { id: auction.id }
          expect(response).to redirect_to(auctions_url)
        end

        it 'sets a success notice' do
          delete :destroy, params: { id: auction.id }
          expect(flash[:notice]).to eq('Auction was successfully destroyed.')
        end
      end

      context 'when user is not the seller' do
        let!(:other_auction) { create(:auction, seller: create(:user)) }

        it 'does not destroy the auction' do
          expect do
            delete :destroy, params: { id: other_auction.id }
          end.not_to change(Auction, :count)
        end

        it 'redirects to auctions path' do
          delete :destroy, params: { id: other_auction.id }
          expect(response).to redirect_to(auctions_path)
        end

        it 'sets an alert message' do
          delete :destroy, params: { id: other_auction.id }
          expect(flash[:alert]).to eq('You are not authorized to perform this action.')
        end
      end
    end
  end
end
