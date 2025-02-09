# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_02_09_171700) do
  create_table "auctions", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.decimal "starting_price", precision: 10, scale: 2, null: false
    t.decimal "minimum_selling_price", precision: 10, scale: 2, null: false
    t.datetime "ends_at", null: false
    t.integer "seller_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.integer "winning_bid_id"
    t.integer "winning_bidder_id"
    t.index ["completed_at"], name: "index_auctions_on_completed_at"
    t.index ["ends_at"], name: "index_auctions_on_ends_at"
    t.index ["seller_id"], name: "index_auctions_on_seller_id"
    t.index ["winning_bid_id"], name: "index_auctions_on_winning_bid_id"
    t.index ["winning_bidder_id"], name: "index_auctions_on_winning_bidder_id"
  end

  create_table "auto_bids", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "auction_id", null: false
    t.decimal "maximum_amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id", "maximum_amount", "created_at"], name: "index_auto_bids_for_processing"
    t.index ["auction_id", "maximum_amount"], name: "index_auto_bids_on_auction_id_and_maximum_amount"
    t.index ["auction_id"], name: "index_auto_bids_on_auction_id"
    t.index ["user_id", "auction_id"], name: "index_auto_bids_on_user_id_and_auction_id", unique: true
    t.index ["user_id"], name: "index_auto_bids_on_user_id"
  end

  create_table "bids", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "auction_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_id", "amount"], name: "index_bids_by_amount"
    t.index ["auction_id", "amount"], name: "index_bids_on_auction_id_and_amount"
    t.index ["auction_id", "user_id", "created_at"], name: "index_bids_for_history"
    t.index ["auction_id"], name: "index_bids_on_auction_id"
    t.index ["user_id", "created_at"], name: "index_bids_by_user_and_date"
    t.index ["user_id"], name: "index_bids_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "auctions", "bids", column: "winning_bid_id"
  add_foreign_key "auctions", "users", column: "seller_id"
  add_foreign_key "auctions", "users", column: "winning_bidder_id"
  add_foreign_key "auto_bids", "auctions"
  add_foreign_key "auto_bids", "users"
  add_foreign_key "bids", "auctions"
  add_foreign_key "bids", "users"
end
