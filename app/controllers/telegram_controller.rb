class TelegramController < ActionController::Base
  # Skip basic auth - webhook is secured by token check
  skip_before_action :verify_authenticity_token

  def webhook
    # Verify this is coming from our bot
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
    # Extract URLs from the message
    urls = URI.extract(text, %w[http https])

    if urls.any?
      urls.each do |url|
        next if url.include?("t.me") # Skip Telegram links

        parsed = StreamingUrlParser.parse(url)
        service = parsed[:service]
        title = parsed[:title]

        next unless service.present? # Only process known streaming services

        # Try to get title from remaining text if not from URL
        if title.blank?
          title = extract_title_from_text(text, url)
        end

        next if title.blank?

        create_item(title: title, url: url, service: service)
      end
    else
      # Plain text — treat as title to look up
      title = text.strip
      return if title.length < 2 || title.start_with?("/") # skip commands

      create_item(title: title)
    end
  end

  def extract_title_from_text(text, url)
    # Remove the URL from the text and use what's left as a title hint
    remaining = text.gsub(url, "").strip
    remaining.present? ? remaining : nil
  end

  def create_item(title:, url: nil, service: nil)
    tmdb = TmdbService.new
    attrs = { title: title, streaming_url: url, streaming_service: service }

    if tmdb.configured?
      enriched = tmdb.enrich_item(title)
      attrs.merge!(enriched) if enriched.any?
    end

    attrs[:media_type] ||= "movie"
    attrs[:streaming_service] ||= service

    item = WatchlistItem.find_or_initialize_by(title: attrs[:title] || title)
    item.assign_attributes(attrs.compact)
    item.save
  end
end
