class TelegramController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def webhook
    token = request.headers["X-Telegram-Bot-Api-Secret-Token"]
    unless token == ENV["TELEGRAM_WEBHOOK_SECRET"]
      render json: { error: "Unauthorized" }, status: :unauthorized and return
    end

    body = JSON.parse(request.body.read) rescue {}
    message = body.dig("message", "text") || body.dig("channel_post", "text") || ""

    if message.present?
      process_message(message)
    end

    render json: { ok: true }
  end

  private

  def process_message(text)
    urls = URI.extract(text, %w[http https])

    if urls.any?
      urls.each do |url|
        next if url.include?("t.me")
        enrich_and_save(url: url)
      end
    else
      # Plain text title — search TMDB directly
      title = text.strip
      return if title.length < 2 || title.start_with?("/")
      enrich_and_save(title: title)
    end
  end

  def enrich_and_save(url: nil, title: nil)
    if url.present?
      result = LinkEnrichmentService.new.enrich(url)
      unless result.success?
        Rails.logger.warn "Telegram: could not enrich #{url}: #{result.error}"
        return
      end
      attrs = result.attributes
    else
      # Plain title — use TMDB directly
      tmdb = TmdbService.new
      return unless tmdb.configured?

      attrs = tmdb.enrich_item(title)
      return if attrs.empty?

      if attrs[:tmdb_id].present?
        cast = tmdb.fetch_cast(attrs[:tmdb_id], attrs[:media_type] || "movie")
        attrs[:cast] = cast if cast.present?
      end
    end

    attrs[:media_type] ||= "movie"

    item = WatchlistItem.find_or_initialize_by(
      title: attrs[:title] || title,
      media_type: attrs[:media_type]
    )
    item.assign_attributes(attrs.compact)
    item.save
  end
end
