class WatchlistItemsController < ApplicationController
  before_action :set_item, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @items = WatchlistItem.recent

    @items = @items.where(status: params[:status]) if params[:status].present?
    @items = @items.where(media_type: params[:media_type]) if params[:media_type].present?
    @items = @items.where(streaming_service: params[:service]) if params[:service].present?

    @want_to_watch_count = WatchlistItem.want_to_watch.count
    @watched_count = WatchlistItem.watched.count
    @available_services = WatchlistItem.available_services
  end

  def show
  end

  def new
    @item = WatchlistItem.new
    @item.streaming_url = params[:url] if params[:url].present?

    if params[:url].present?
      parsed = StreamingUrlParser.parse(params[:url])
      @item.streaming_service = parsed[:service]
      @item.title = parsed[:title] if parsed[:title].present?
    end
  end

  def create
    # If a URL is provided and we have Anthropic configured, try full enrichment first
    if item_params[:streaming_url].present? && AnthropicService.new.configured?
      result = LinkEnrichmentService.new.enrich(item_params[:streaming_url])

      unless result.success?
        @item = WatchlistItem.new(item_params)
        @item.errors.add(:base, result.error)
        return render :new, status: :unprocessable_entity
      end

      @item = WatchlistItem.new(item_params.merge(result.attributes.transform_keys(&:to_s)))
    else
      @item = WatchlistItem.new(item_params)

      # Auto-detect service from URL if not set
      if @item.streaming_url.present? && @item.streaming_service.blank?
        @item.streaming_service = WatchlistItem.detect_service_from_url(@item.streaming_url)
      end

      # Enrich with TMDB if we have a title
      if @item.title.present? && @item.tmdb_id.blank?
        tmdb = TmdbService.new
        if tmdb.configured?
          enriched = tmdb.enrich_item(@item.title, media_type: @item.media_type.presence)
          if enriched.any?
            @item.assign_attributes(enriched.except(:title))
            @item.media_type = enriched[:media_type] if @item.media_type.blank?
          end
          if @item.tmdb_id.present?
            cast = tmdb.fetch_cast(@item.tmdb_id, @item.media_type)
            @item.cast = cast if cast.present?
          end
        end
      end
    end

    @item.media_type = "movie" if @item.media_type.blank?

    if @item.save
      respond_to do |format|
        format.html { redirect_to @item, notice: "\"#{@item.title}\" added to your watchlist!" }
        format.json { render json: @item, status: :created }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "\"#{@item.title}\" updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to watchlist_items_path, notice: "\"#{@item.title}\" removed from your watchlist."
  end

  def toggle_status
    new_status = @item.want_to_watch? ? "watched" : "want_to_watch"
    @item.update(status: new_status)

    respond_to do |format|
      format.html { redirect_back fallback_location: watchlist_items_path }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("item_#{@item.id}", partial: "watchlist_items/card", locals: { item: @item }),
          turbo_stream.replace("counts", partial: "watchlist_items/counts")
        ]
      end
    end
  end

  def search
    query = params[:q].to_s.strip
    @results = []

    if query.length >= 2
      tmdb = TmdbService.new
      if tmdb.configured?
        @results = tmdb.search(query).first(8)
      end
    end

    render json: @results.map { |r|
      {
        id: r["id"],
        title: r["title"] || r["name"],
        media_type: r["media_type"],
        release_date: r["release_date"] || r["first_air_date"],
        poster_path: r["poster_path"] ? "https://image.tmdb.org/t/p/w92#{r['poster_path']}" : nil,
        overview: r["overview"]&.truncate(120)
      }
    }
  end

  # Quick-add from search results — accepts either a tmdb_id (fetches full details)
  # or a full pre-enriched payload (from URL enrichment).
  def quick_add
    payload = params.permit(
      :tmdb_id, :media_type, :title, :source,
      :overview, :poster_path, :backdrop_path, :vote_average,
      :genres, :runtime, :release_date, :original_language,
      :cast, :streaming_service, :streaming_url
    ).to_h.symbolize_keys

    tmdb = TmdbService.new

    if payload[:tmdb_id].present?
      media_type = payload[:media_type].presence || "movie"

      # Fetch full details from TMDB (poster, genres, cast, etc.)
      attrs = tmdb.configured? ? (tmdb.details(payload[:tmdb_id], media_type) || {}) : {}

      if attrs.empty?
        # Fallback to whatever we were given
        attrs = payload.slice(:title, :media_type, :overview, :poster_path,
                              :backdrop_path, :vote_average, :genres, :runtime,
                              :release_date, :original_language)
        attrs[:tmdb_id] = payload[:tmdb_id]
      end

      # Fetch cast separately
      if tmdb.configured? && attrs[:tmdb_id].present?
        cast = tmdb.fetch_cast(attrs[:tmdb_id], attrs[:media_type] || media_type)
        attrs[:cast] = cast if cast.present?
      end

      # Carry over any URL/service info from the payload
      attrs[:streaming_url] = payload[:streaming_url] if payload[:streaming_url].present?
      attrs[:streaming_service] = payload[:streaming_service] if payload[:streaming_service].present?
      # If we were given pre-enriched cast/service and TMDB didn't override, keep it
      attrs[:cast] ||= payload[:cast]
      attrs[:streaming_service] ||= payload[:streaming_service]
    else
      # Full payload provided (e.g. from URL enrichment) — use as-is
      attrs = payload.except(:source)
    end

    attrs[:media_type] ||= "movie"
    attrs[:status] = "want_to_watch"

    @item = WatchlistItem.new(attrs)

    if @item.save
      render json: { success: true, id: @item.id, title: @item.title, url: watchlist_item_path(@item) }
    else
      render json: { success: false, errors: @item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Enrich a URL via AJAX before form submission — gives instant preview
  def enrich_url
    url = params[:url].to_s.strip
    result = LinkEnrichmentService.new.enrich(url)

    if result.success?
      attrs = result.attributes
      render json: {
        success: true,
        title: attrs[:title],
        media_type: attrs[:media_type],
        streaming_service: attrs[:streaming_service],
        overview: attrs[:overview],
        poster_path: attrs[:poster_path] ? "https://image.tmdb.org/t/p/w500#{attrs[:poster_path]}" : nil,
        vote_average: attrs[:vote_average],
        genres: attrs[:genres],
        runtime: attrs[:runtime],
        release_date: attrs[:release_date],
        cast: attrs[:cast],
        tmdb_id: attrs[:tmdb_id],
        backdrop_path: attrs[:backdrop_path],
        original_language: attrs[:original_language]
      }
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = WatchlistItem.find(params[:id])
  end

  def item_params
    params.require(:watchlist_item).permit(
      :title, :media_type, :status, :streaming_service,
      :streaming_url, :tmdb_id, :overview, :poster_path,
      :backdrop_path, :vote_average, :genres, :runtime,
      :release_date, :original_language, :notes, :cast
    )
  end
end
