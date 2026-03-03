# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database from scratch, this should work
# as the primary way to setup your database.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the more likely it is to break).

ActiveRecord::Schema[8.0].define(version: 2026_03_03_000001) do
  create_table "watchlist_items", force: :cascade do |t|
    t.string "title", null: false
    t.string "media_type", null: false, default: "movie"
    t.string "status", null: false, default: "want_to_watch"
    t.string "streaming_service"
    t.string "streaming_url"
    t.integer "tmdb_id"
    t.text "overview"
    t.string "poster_path"
    t.string "backdrop_path"
    t.decimal "vote_average", precision: 4, scale: 2
    t.string "genres"
    t.integer "runtime"
    t.string "release_date"
    t.string "original_language"
    t.text "notes"
    t.text "cast"
    t.datetime "watched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["media_type"], name: "index_watchlist_items_on_media_type"
    t.index ["status"], name: "index_watchlist_items_on_status"
    t.index ["streaming_service"], name: "index_watchlist_items_on_streaming_service"
    t.index ["tmdb_id"], name: "index_watchlist_items_on_tmdb_id"
  end
end
