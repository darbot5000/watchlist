class CreateWatchlistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :watchlist_items do |t|
      t.string :title, null: false
      t.string :media_type, null: false, default: "movie" # movie or tv
      t.string :status, null: false, default: "want_to_watch"
      t.string :streaming_service
      t.string :streaming_url
      t.integer :tmdb_id
      t.text :overview
      t.string :poster_path
      t.string :backdrop_path
      t.decimal :vote_average, precision: 4, scale: 2
      t.string :genres
      t.integer :runtime
      t.string :release_date
      t.string :original_language
      t.text :notes
      t.datetime :watched_at

      t.timestamps
    end

    add_index :watchlist_items, :status
    add_index :watchlist_items, :streaming_service
    add_index :watchlist_items, :tmdb_id
    add_index :watchlist_items, :media_type
  end
end
