# Sample seed data for development
puts "Seeding watchlist items..."

items = [
  {
    title: "Dune: Part Two",
    media_type: "movie",
    status: "watched",
    streaming_service: "Max",
    tmdb_id: 693134,
    overview: "Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family.",
    vote_average: 8.2,
    genres: "Science Fiction, Adventure",
    runtime: 166,
    release_date: "2024-02-28",
    watched_at: 2.weeks.ago
  },
  {
    title: "Shogun",
    media_type: "tv",
    status: "watched",
    streaming_service: "Hulu",
    tmdb_id: 126308,
    overview: "In feudal Japan, a mysterious European ship is found adrift in Japanese waters, carrying a navigator who will become a pivotal player in a dangerous political power struggle.",
    vote_average: 8.8,
    genres: "Drama, History, War",
    release_date: "2024-02-27",
    watched_at: 1.month.ago
  },
  {
    title: "Severance",
    media_type: "tv",
    status: "want_to_watch",
    streaming_service: "Apple TV+",
    tmdb_id: 95396,
    overview: "Mark leads a team of office workers whose memories have been surgically divided between their work and personal lives.",
    vote_average: 8.7,
    genres: "Sci-Fi & Fantasy, Drama, Mystery"
  }
]

items.each do |item|
  WatchlistItem.find_or_create_by(title: item[:title], media_type: item[:media_type]) do |w|
    w.assign_attributes(item)
  end
end

puts "Done! #{WatchlistItem.count} items in watchlist."
