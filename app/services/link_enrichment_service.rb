class LinkEnrichmentService
  Result = Struct.new(:success, :attributes, :error, keyword_init: true) do
    def success? = success
  end

  def initialize
    @anthropic = AnthropicService.new
    @tmdb = TmdbService.new
  end

  # Given a URL, returns a Result with enriched attributes or an error message.
  def enrich(url)
    return Result.new(success: false, error: "No URL provided") if url.blank?

    # 1. Fetch page content
    content, fetch_error = fetch_content(url)
    return Result.new(success: false, error: fetch_error) if fetch_error

    # 2. Ask Claude to identify the media
    unless @anthropic.configured?
      return Result.new(success: false, error: "Anthropic API key not configured")
    end

    identified = @anthropic.identify_media(content: content, url: url)

    unless identified
      return Result.new(
        success: false,
        error: "Could not identify a movie or TV show from that link. Try a more specific URL or add it manually."
      )
    end

    title = identified["title"]
    media_type = identified["media_type"]
    streaming_service = identified["streaming_service"] || WatchlistItem.detect_service_from_url(url)

    # 3. Enrich with TMDB
    attrs = { title: title, media_type: media_type, streaming_url: url, streaming_service: streaming_service }

    if @tmdb.configured?
      tmdb_attrs = @tmdb.enrich_item(title, media_type: media_type)
      attrs.merge!(tmdb_attrs) if tmdb_attrs.any?

      # Fetch cast if we have a TMDB ID
      if attrs[:tmdb_id].present?
        cast = @tmdb.fetch_cast(attrs[:tmdb_id], attrs[:media_type] || media_type)
        attrs[:cast] = cast if cast.present?
      end
    end

    attrs[:streaming_service] ||= streaming_service
    attrs[:media_type] ||= media_type || "movie"

    Result.new(success: true, attributes: attrs)
  end

  private

  def fetch_content(url)
    # YouTube: use oEmbed for clean title/description
    if youtube_url?(url)
      return fetch_youtube_content(url)
    end

    response = HTTParty.get(url, {
      timeout: 10,
      follow_redirects: true,
      headers: { "User-Agent" => "Mozilla/5.0 (compatible; Watchlist/1.0)" }
    })

    return [nil, "Failed to fetch URL (status #{response.code})"] unless response.success?

    # Strip HTML tags to get readable text
    text = response.body.to_s
      .gsub(/<script[^>]*>.*?<\/script>/mi, "")
      .gsub(/<style[^>]*>.*?<\/style>/mi, "")
      .gsub(/<[^>]+>/, " ")
      .gsub(/\s+/, " ")
      .strip
      .truncate(10_000)

    [text, nil]
  rescue => e
    [nil, "Could not fetch URL: #{e.message}"]
  end

  def fetch_youtube_content(url)
    oembed_url = "https://www.youtube.com/oembed?url=#{CGI.escape(url)}&format=json"
    response = HTTParty.get(oembed_url, timeout: 10)

    if response.success?
      data = response.parsed_response
      content = "YouTube Video\nTitle: #{data['title']}\nAuthor: #{data['author_name']}"
      return [content, nil]
    end

    # Fall back to scraping the page
    fetch_page_content(url)
  rescue => e
    [nil, "Could not fetch YouTube content: #{e.message}"]
  end

  def youtube_url?(url)
    url.include?("youtube.com") || url.include?("youtu.be")
  end
end
