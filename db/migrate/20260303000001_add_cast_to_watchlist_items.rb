class AddCastToWatchlistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :watchlist_items, :cast, :text
  end
end
