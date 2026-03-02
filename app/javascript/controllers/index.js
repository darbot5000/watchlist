import { application } from "./application"
import TmdbSearchController from "./tmdb_search_controller"
import UrlDetectController from "./url_detect_controller"

application.register("tmdb-search", TmdbSearchController)
application.register("url-detect", UrlDetectController)
