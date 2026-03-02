class WatchlistItem < ApplicationRecord
  STATUSES = %w[want_to_watch watched].freeze
  MEDIA_TYPES = %w[movie tv].freeze

  STREAMING_SERVICES = {
    "netflix.com" => "Netflix",
    "max.com" => "Max",
    "hbo.com" => "Max",
    "disneyplus.com" => "Disney+",
    "hulu.com" => "Hulu",
    "primevideo.com" => "Prime Video",
    "amazon.com/prime" => "Prime Video",
    "apple.com/apple-tv-plus" => "Apple TV+",
    "tv.apple.com" => "Apple TV+",
    "peacocktv.com" => "Peacock",
    "paramountplus.com" => "Paramount+",
    "mubi.com" => "MUBI",
    "criterion.com" => "Criterion Channel",
    "shudder.com" => "Shudder",
    "youtube.com" => "YouTube"
  }.freeze

  TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p".freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :media_type, inclusion: { in: MEDIA_TYPES }

  scope :want_to_watch, -> { where(status: "want_to_watch") }
  scope :watched, -> { where(status: "watched") }
  scope :movies, -> { where(media_type: "movie") }
  scope :tv_shows, -> { where(media_type: "tv") }
  scope :by_service, ->(service) { where(streaming_service: service) }
  scope :recent, -> { order(created_at: :desc) }

  before_save :set_watched_at, if: :status_changed_to_watched?

  def poster_url(size = "w500")
    return nil unless poster_path.present?
    "#{TMDB_IMAGE_BASE}/#{size}#{poster_path}"
  end

  def backdrop_url(size = "w1280")
    return nil unless backdrop_path.present?
    "#{TMDB_IMAGE_BASE}/#{size}#{backdrop_path}"
  end

  def genres_list
    genres&.split(",")&.map(&:strip) || []
  end

  def formatted_runtime
    return nil unless runtime.present? && runtime > 0
    hours = runtime / 60
    mins = runtime % 60
    if hours > 0
      "#{hours}h #{mins}m"
    else
      "#{mins}m"
    end
  end

  def release_year
    release_date&.split("-")&.first
  end

  def status_label
    status == "want_to_watch" ? "Want to Watch" : "Watched"
  end

  def want_to_watch?
    status == "want_to_watch"
  end

  def watched?
    status == "watched"
  end

  def self.detect_service_from_url(url)
    return nil if url.blank?
    STREAMING_SERVICES.each do |domain, service|
      return service if url.include?(domain)
    end
    nil
  end

  def self.available_services
    WatchlistItem.where.not(streaming_service: nil)
                 .distinct
                 .pluck(:streaming_service)
                 .compact
                 .sort
  end

  private

  def status_changed_to_watched?
    status_changed? && status == "watched"
  end

  def set_watched_at
    self.watched_at = Time.current if watched_at.nil?
  end
end
