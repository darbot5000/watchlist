class TmdbService
  BASE_URL = "https://api.themoviedb.org/3".freeze

  def initialize
    @api_key = ENV["TMDB_API_KEY"]
  end

  def configured?
    @api_key.present?
  end

  # Search for movies or TV shows by title
  def search(query, media_type: nil)
    return [] unless configured?

    if media_type
      search_by_type(query, media_type)
    else
      movies = search_by_type(query, "movie")
      shows = search_by_type(query, "tv")
      (movies + shows).sort_by { |r| -r["popularity"].to_f }
    end
  end

  # Get details for a specific item
  def details(tmdb_id, media_type)
    return nil unless configured?

    endpoint = media_type == "tv" ? "tv" : "movie"
    response = get("/#{endpoint}/#{tmdb_id}")
    return nil unless response.success?

    parse_details(response.parsed_response, media_type)
  end

  # Fetch top-billed cast for a TMDB item
  def fetch_cast(tmdb_id, media_type, limit: 8)
    return nil unless configured?

    endpoint = media_type == "tv" ? "tv" : "movie"
    response = get("/#{endpoint}/#{tmdb_id}/credits")
    return nil unless response.success?

    cast = response.parsed_response["cast"] || []
    cast.first(limit).map { |c| c["name"] }.join(", ")
  end

  # Find best match and return enriched attributes
  def enrich_item(title, media_type: nil)
    return {} unless configured?

    results = search(title, media_type: media_type)
    return {} if results.empty?

    best = results.first
    detected_type = best["media_type"] || media_type || "movie"
    details(best["id"], detected_type) || {}
  end

  private

  def search_by_type(query, media_type)
    endpoint = media_type == "tv" ? "search/tv" : "search/movie"
    response = get("/#{endpoint}", query: query)
    return [] unless response.success?

    results = response.parsed_response["results"] || []
    results.map { |r| r.merge("media_type" => media_type) }
  end

  def parse_details(data, media_type)
    genres = data["genres"]&.map { |g| g["name"] }&.join(", ")

    {
      tmdb_id: data["id"],
      title: media_type == "tv" ? data["name"] : data["title"],
      overview: data["overview"],
      poster_path: data["poster_path"],
      backdrop_path: data["backdrop_path"],
      vote_average: data["vote_average"],
      genres: genres,
      runtime: media_type == "tv" ? data.dig("episode_run_time", 0) : data["runtime"],
      release_date: media_type == "tv" ? data["first_air_date"] : data["release_date"],
      original_language: data["original_language"],
      media_type: media_type
    }
  end

  def get(path, params = {})
    HTTParty.get(
      "#{BASE_URL}#{path}",
      query: params.merge(api_key: @api_key),
      timeout: 10
    )
  end
end
