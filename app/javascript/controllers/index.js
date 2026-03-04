import { application } from "./application"
import TmdbSearchController from "./tmdb_search_controller"
import UrlDetectController from "./url_detect_controller"
import UrlEnrichController from "./url_enrich_controller"
import WatchlistSearchController from "./watchlist_search_controller"

application.register("tmdb-search", TmdbSearchController)
application.register("url-detect", UrlDetectController)
application.register("url-enrich", UrlEnrichController)
application.register("watchlist-search", WatchlistSearchController)
