class AddIndexesToAutoBids < ActiveRecord::Migration[7.0]
  def change
    # Indexes for auto_bids table
    unless index_exists?(:auto_bids, [:auction_id, :maximum_amount, :created_at], name: 'index_auto_bids_for_processing')
      add_index :auto_bids, [:auction_id, :maximum_amount, :created_at], 
        name: 'index_auto_bids_for_processing'
    end
    
    # Skip this index since it already exists
    # add_index :auto_bids, [:user_id, :auction_id], unique: true
    
    # Indexes for bids table
    unless index_exists?(:bids, [:auction_id, :amount], name: 'index_bids_by_amount')
      add_index :bids, [:auction_id, :amount], 
        name: 'index_bids_by_amount'
    end

    unless index_exists?(:bids, [:user_id, :created_at], name: 'index_bids_by_user_and_date')
      add_index :bids, [:user_id, :created_at], 
        name: 'index_bids_by_user_and_date'
    end

    unless index_exists?(:bids, [:auction_id, :user_id, :created_at], name: 'index_bids_for_history')
      add_index :bids, [:auction_id, :user_id, :created_at], 
        name: 'index_bids_for_history'
    end
  end
end
