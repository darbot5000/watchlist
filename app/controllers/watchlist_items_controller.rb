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

    # Pre-fill from URL if provided
    if params[:url].present?
      parsed = StreamingUrlParser.parse(params[:url])
      @item.streaming_service = parsed[:service]
      @item.title = parsed[:title] if parsed[:title].present?
    end
  end

  def create
    @item = WatchlistItem.new(item_params)

    # Auto-detect service from URL if not set
    if @item.streaming_url.present? && @item.streaming_service.blank?
      @item.streaming_service = WatchlistItem.detect_service_from_url(@item.streaming_url)
    end

    # Enrich with TMDB data if title is present
    if @item.title.present? && @item.tmdb_id.blank?
      tmdb = TmdbService.new
      if tmdb.configured?
        enriched = tmdb.enrich_item(@item.title, media_type: @item.media_type.presence)
        if enriched.any?
          @item.assign_attributes(enriched.except(:title)) # keep user-entered title
          @item.media_type = enriched[:media_type] if @item.media_type.blank?
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

  private

  def set_item
    @item = WatchlistItem.find(params[:id])
  end

  def item_params
    params.require(:watchlist_item).permit(
      :title, :media_type, :status, :streaming_service,
      :streaming_url, :tmdb_id, :overview, :poster_path,
      :backdrop_path, :vote_average, :genres, :runtime,
      :release_date, :original_language, :notes
    )
  end
end
