class StreamingUrlParser
  # Extract a title guess and streaming service from a URL
  def self.parse(url)
    return { service: nil, title: nil } if url.blank?

    service = WatchlistItem.detect_service_from_url(url)
    title = extract_title_from_url(url, service)

    { service: service, title: title }
  end

  private

  def self.extract_title_from_url(url, service)
    uri = URI.parse(url) rescue nil
    return nil unless uri

    path = uri.path.to_s

    case service
    when "Netflix"
      # netflix.com/title/show-name or browse after login
      match = path.match(%r{/title/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Max"
      # max.com/movies/movie-name or max.com/shows/show-name
      match = path.match(%r{/(?:movies|shows)/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Disney+"
      # disneyplus.com/movies/title/id or series
      match = path.match(%r{/(?:movies|series)/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Hulu"
      # hulu.com/series/show-name or /movie/
      match = path.match(%r{/(?:series|movie)/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Apple TV+"
      # tv.apple.com/us/movie/title/id
      match = path.match(%r{/(?:movie|show)/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Prime Video"
      # primevideo.com/detail/title-name
      match = path.match(%r{/detail/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Peacock"
      match = path.match(%r{/watch/([^/?]+)})
      humanize_slug(match[1]) if match
    when "Paramount+"
      match = path.match(%r{/shows?/([^/?]+)})
      humanize_slug(match[1]) if match
    end
  end

  def self.humanize_slug(slug)
    return nil if slug.blank?
    # Remove IDs (long alphanumeric strings), clean up slug
    cleaned = slug.gsub(/-[a-z0-9]{8,}$/, "")
                  .gsub("-", " ")
                  .split
                  .map(&:capitalize)
                  .join(" ")
    cleaned.present? ? cleaned : nil
  end
end
