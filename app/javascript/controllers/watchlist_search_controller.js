import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "spinner", "error"]

  connect() {
    this.debounceTimer = null
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    console.log("[WatchlistSearch] controller connected")
  }

  onInput(event) {
    const val = event.target.value.trim()
    clearTimeout(this.debounceTimer)
    this.hideError()

    if (!val) {
      this.clearResults()
      return
    }

    if (this.isUrl(val)) {
      this.debounceTimer = setTimeout(() => this.enrichUrl(val), 700)
    } else if (val.length >= 2) {
      this.debounceTimer = setTimeout(() => this.searchTmdb(val), 350)
    } else {
      this.clearResults()
    }
  }

  onKeydown(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    clearTimeout(this.debounceTimer)
    this.submit()
  }

  onSearch(event) {
    event.preventDefault()
    clearTimeout(this.debounceTimer)
    this.submit()
  }

  submit() {
    const val = this.inputTarget.value.trim()
    if (!val) return
    this.hideError()
    if (this.isUrl(val)) {
      this.enrichUrl(val)
    } else if (val.length >= 1) {
      this.searchTmdb(val)
    }
  }

  // ── URL enrichment ──────────────────────────────────────────────────────────

  async enrichUrl(url) {
    console.log("[WatchlistSearch] enriching URL:", url)
    this.showSpinner("Analyzing link…")
    this.clearResults()

    try {
      const response = await fetch("/watchlist_items/enrich_url", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ url })
      })

      const data = await response.json()
      this.hideSpinner()
      console.log("[WatchlistSearch] enrich response:", data)

      if (data.success) {
        this.renderResults([{ ...data, source: "url", streaming_url: url }])
      } else {
        this.showError(data.error || "Couldn't identify a show or movie from that link.")
      }
    } catch (e) {
      this.hideSpinner()
      console.error("[WatchlistSearch] enrichUrl error:", e)
      this.showError("Could not reach the server. Please try again.")
    }
  }

  // ── TMDB text search ────────────────────────────────────────────────────────

  async searchTmdb(query) {
    console.log("[WatchlistSearch] searching TMDB:", query)
    this.showSpinner("Searching…")
    this.clearResults()

    try {
      const response = await fetch(`/watchlist_items/search?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })
      const results = await response.json()
      this.hideSpinner()
      console.log("[WatchlistSearch] search results:", results.length)

      if (results.length === 0) {
        this.showError("No results found. Try a different title.")
      } else {
        this.renderResults(results.map(r => ({ ...r, source: "tmdb" })))
      }
    } catch (e) {
      this.hideSpinner()
      console.error("[WatchlistSearch] searchTmdb error:", e)
      this.showError("Search failed. Please try again.")
    }
  }

  // ── Render result cards ─────────────────────────────────────────────────────

  renderResults(results) {
    const container = this.resultsTarget

    container.innerHTML = results.map((r, i) => {
      const title = this.esc(r.title || r.name || "")
      const typeBadge = r.media_type === "tv"
        ? `<span class="text-xs px-2 py-0.5 rounded-full bg-purple-600/30 text-purple-400 border border-purple-600/30">TV Show</span>`
        : `<span class="text-xs px-2 py-0.5 rounded-full bg-blue-600/30 text-blue-400 border border-blue-600/30">Movie</span>`

      const year = (r.release_date || r.first_air_date || "").substring(0, 4)
      const rating = r.vote_average ? `<span class="text-yellow-400 text-xs">★ ${parseFloat(r.vote_average).toFixed(1)}</span>` : ""
      const service = r.streaming_service ? `<span class="text-teal-400 text-xs">${this.esc(r.streaming_service)}</span>` : ""
      const overview = r.overview ? `<p class="text-gray-400 text-xs mt-1 line-clamp-2">${this.esc(r.overview)}</p>` : ""
      const cast = r.cast ? `<p class="text-gray-500 text-xs mt-1">Starring: ${this.esc(r.cast)}</p>` : ""

      const poster = (r.poster_path && r.poster_path.startsWith("http"))
        ? r.poster_path
        : r.poster_path
          ? `https://image.tmdb.org/t/p/w92${r.poster_path}`
          : null

      const posterEl = poster
        ? `<img src="${poster}" alt="" class="w-14 h-20 object-cover rounded-lg flex-shrink-0 shadow">`
        : `<div class="w-14 h-20 bg-gray-700 rounded-lg flex-shrink-0 flex items-center justify-center text-gray-500 text-xl">🎬</div>`

      const payloadObj = {
        tmdb_id: r.tmdb_id || r.id,
        media_type: r.media_type || "movie",
        title: r.title || r.name,
        source: r.source
      }
      if (r.source === "url") {
        payloadObj.overview = r.overview
        payloadObj.poster_path = r.poster_path_raw || (r.poster_path ? r.poster_path.replace("https://image.tmdb.org/t/p/w500", "") : "")
        payloadObj.backdrop_path = r.backdrop_path
        payloadObj.vote_average = r.vote_average
        payloadObj.genres = r.genres
        payloadObj.runtime = r.runtime
        payloadObj.release_date = r.release_date
        payloadObj.original_language = r.original_language
        payloadObj.cast = r.cast
        payloadObj.streaming_service = r.streaming_service
        payloadObj.streaming_url = r.streaming_url
      }

      const payload = this.esc(JSON.stringify(payloadObj))

      return `
        <div class="flex items-center gap-4 p-4 bg-gray-800/60 border border-gray-700 rounded-xl" id="result-${i}">
          ${posterEl}
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap mb-1">
              ${typeBadge}
              ${year ? `<span class="text-gray-500 text-xs">${year}</span>` : ""}
              ${rating}
              ${service}
            </div>
            <p class="text-white font-semibold truncate">${title}</p>
            ${overview}
            ${cast}
          </div>
          <button type="button"
                  class="flex-shrink-0 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors whitespace-nowrap"
                  data-payload="${payload}"
                  data-result-index="${i}"
                  data-action="click->watchlist-search#addItem">
            + Add
          </button>
        </div>
      `
    }).join("")
  }

  // ── Add item ────────────────────────────────────────────────────────────────

  async addItem(event) {
    const btn = event.currentTarget
    const payload = JSON.parse(btn.dataset.payload)
    const idx = btn.dataset.resultIndex
    const card = document.getElementById(`result-${idx}`)

    console.log("[WatchlistSearch] adding item:", payload.title)
    btn.disabled = true
    btn.textContent = "Adding…"

    try {
      const response = await fetch("/watchlist_items/quick_add", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify(payload)
      })

      const data = await response.json()
      console.log("[WatchlistSearch] quick_add response:", data)

      if (data.success) {
        if (card) {
          card.innerHTML = `
            <div class="flex items-center gap-3 text-green-400 py-2">
              <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
              </svg>
              <span class="font-medium">"${this.esc(data.title)}" added to your watchlist!</span>
              <a href="${data.url}" class="ml-auto text-indigo-400 hover:text-indigo-300 text-sm underline">View</a>
            </div>
          `
        }
      } else {
        btn.disabled = false
        btn.textContent = "+ Add"
        this.showError(data.errors?.join(", ") || "Failed to add. Please try again.")
      }
    } catch (e) {
      btn.disabled = false
      btn.textContent = "+ Add"
      console.error("[WatchlistSearch] addItem error:", e)
      this.showError("Could not reach the server. Please try again.")
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  isUrl(str) {
    try { new URL(str); return str.startsWith("http://") || str.startsWith("https://") } catch { return false }
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
  }

  showSpinner(msg) {
    this.spinnerTarget.querySelector("span").textContent = msg || "Loading…"
    this.spinnerTarget.classList.remove("hidden")
  }

  hideSpinner() {
    this.spinnerTarget.classList.add("hidden")
  }

  showError(msg) {
    this.errorTarget.textContent = msg
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }

  esc(str) {
    return String(str ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
