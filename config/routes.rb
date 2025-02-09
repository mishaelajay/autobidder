Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root 'auctions#index'

  # Change from my_auctions to just auctions index with a filter
  get 'auctions', to: 'auctions#index', as: :actions, defaults: { filter: 'mine' }
  get 'bids', to: 'bids#index', as: :bids

  resources :auctions do
    resources :bids, only: [:create]
    resources :auto_bids, only: [:create, :destroy]
    
    member do
      get 'bid_history'  # To view detailed bid history
      get 'winner'       # To check auction winner after it ends
    end
  end

  # Dashboard routes
  get 'dashboard', to: 'dashboard#index'
  namespace :dashboard do
    resources :auctions, only: [:index] do
      collection do
        get 'active'
        get 'ended'
        get 'won'
      end
    end
    resources :bids, only: [:index]
    resources :auto_bids, only: [:index]
  end
end
