import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.debounceTimer = null
  }

  search(event) {
    const query = event.target.value.trim()
    clearTimeout(this.debounceTimer)

    if (query.length < 2) {
      this.hideResults()
      return
    }

    this.debounceTimer = setTimeout(() => {
      this.fetchResults(query)
    }, 300)
  }

  async fetchResults(query) {
    try {
      const response = await fetch(`/watchlist_items/search?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })
      const results = await response.json()
      this.renderResults(results)
    } catch (e) {
      console.error("TMDB search error", e)
    }
  }

  renderResults(results) {
    const container = document.getElementById("tmdb_results")
    if (!container) return

    if (results.length === 0) {
      container.classList.add("hidden")
      return
    }

    container.innerHTML = results.map(r => `
      <button type="button"
              class="w-full flex items-center gap-3 p-3 hover:bg-gray-700 transition-colors text-left"
              data-tmdb-id="${r.id}"
              data-title="${this.escapeHtml(r.title)}"
              data-media-type="${r.media_type || 'movie'}"
              data-release-date="${r.release_date || ''}"
              data-overview="${this.escapeHtml(r.overview || '')}"
              onclick="window.selectTmdbResult(this)">
        ${r.poster_path
          ? `<img src="${r.poster_path}" alt="" class="w-10 h-14 object-cover rounded flex-shrink-0">`
          : `<div class="w-10 h-14 bg-gray-700 rounded flex-shrink-0"></div>`
        }
        <div class="min-w-0">
          <p class="text-white text-sm font-medium truncate">${this.escapeHtml(r.title)}</p>
          <p class="text-gray-400 text-xs">${r.media_type === 'tv' ? 'TV Show' : 'Movie'} · ${r.release_date ? r.release_date.substring(0, 4) : 'N/A'}</p>
          ${r.overview ? `<p class="text-gray-500 text-xs mt-0.5 line-clamp-1">${this.escapeHtml(r.overview)}</p>` : ''}
        </div>
      </button>
    `).join('<div class="border-t border-gray-700"></div>')

    container.classList.remove("hidden")
  }

  hideResults() {
    const container = document.getElementById("tmdb_results")
    if (container) container.classList.add("hidden")
  }

  escapeHtml(str) {
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}

// Global handler for result selection
window.selectTmdbResult = function(el) {
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.value = val }

  set("title_field", el.dataset.title)
  set("tmdb_id_field", el.dataset.tmdbId)
  set("release_date_field", el.dataset.releaseDate)
  set("overview_field", el.dataset.overview)

  // Set media type select
  const mediaTypeSelect = document.querySelector("select[name='watchlist_item[media_type]']")
  if (mediaTypeSelect) mediaTypeSelect.value = el.dataset.mediaType || "movie"

  document.getElementById("tmdb_results").classList.add("hidden")
  document.getElementById("tmdb_search").value = ""
}
