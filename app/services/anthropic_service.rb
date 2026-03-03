class AnthropicService
  API_URL = "https://api.anthropic.com/v1/messages".freeze
  MODEL = "claude-3-5-haiku-20241022".freeze

  def initialize
    @api_key = ENV["ANTHROPIC_API_KEY"]
  end

  def configured?
    @api_key.present?
  end

  # Given page content (text), identify the movie/show.
  # Returns a hash or nil if not identifiable.
  def identify_media(content:, url: nil)
    return nil unless configured?

    prompt = <<~PROMPT
      You are helping identify a movie or TV show from web page content.

      URL: #{url || "unknown"}

      PAGE CONTENT:
      #{content.to_s.truncate(8000)}

      Based on this content, identify the movie or TV show being referenced.
      If this page is about a specific movie or TV show (including trailers, reviews, Wikipedia pages, streaming pages, news articles, YouTube videos about a specific title), return a JSON object.
      If you cannot confidently identify a specific movie or TV show, return {"identified": false}.

      Return ONLY valid JSON, no explanation. Example:
      {
        "identified": true,
        "title": "The Dark Knight",
        "media_type": "movie",
        "year": "2008",
        "streaming_service": "Max"
      }

      Notes:
      - media_type must be "movie" or "tv"
      - streaming_service should be the service from the URL if detectable, otherwise null
      - year is the release year or first air year, if known
      - If the page is about a TV show episode, return the show title not the episode title
    PROMPT

    response = HTTParty.post(
      API_URL,
      headers: {
        "x-api-key" => @api_key,
        "anthropic-version" => "2023-06-01",
        "content-type" => "application/json"
      },
      body: {
        model: MODEL,
        max_tokens: 256,
        messages: [{ role: "user", content: prompt }]
      }.to_json,
      timeout: 20
    )

    return nil unless response.success?

    text = response.parsed_response.dig("content", 0, "text").to_s.strip
    # Strip markdown code fences if present
    text = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    parsed = JSON.parse(text)
    return nil unless parsed["identified"] == true

    parsed
  rescue JSON::ParserError, StandardError => e
    Rails.logger.error "AnthropicService error: #{e.message}"
    nil
  end
end
