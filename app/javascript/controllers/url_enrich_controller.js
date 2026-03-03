import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "spinner", "error"]

  connect() {
    this.debounceTimer = null
  }

  enrich(event) {
    const url = event.target.value.trim()
    clearTimeout(this.debounceTimer)

    if (!this.isValidUrl(url)) {
      this.hidePreview()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchEnrichment(url), 600)
  }

  async fetchEnrichment(url) {
    this.showSpinner()
    this.hideError()

    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch("/watchlist_items/enrich_url", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ url })
      })

      const data = await response.json()
      this.hideSpinner()

      if (data.success) {
        this.populateFields(data)
        this.showPreview(data)
      } else {
        this.showError(data.error)
      }
    } catch (e) {
      this.hideSpinner()
      this.showError("Could not reach the server. Please try again.")
    }
  }

  populateFields(data) {
    const set = (id, val) => { const el = document.getElementById(id); if (el && val != null) el.value = val }

    set("title_field", data.title)
    set("tmdb_id_field", data.tmdb_id)
    set("poster_path_field", data.poster_path_raw || data.poster_path?.replace("https://image.tmdb.org/t/p/w500", ""))
    set("backdrop_path_field", data.backdrop_path)
    set("overview_field", data.overview)
    set("vote_average_field", data.vote_average)
    set("genres_field", data.genres)
    set("runtime_field", data.runtime)
    set("release_date_field", data.release_date)
    set("original_language_field", data.original_language)
    set("cast_field", data.cast)
    set("streaming_service_field", data.streaming_service)

    const mediaSelect = document.querySelector("select[name='watchlist_item[media_type]']")
    if (mediaSelect && data.media_type) mediaSelect.value = data.media_type
  }

  showPreview(data) {
    const preview = document.getElementById("url_enrich_preview")
    if (!preview) return

    preview.innerHTML = `
      <div class="flex gap-4 items-start">
        ${data.poster_path
          ? `<img src="${data.poster_path}" alt="" class="w-16 h-24 object-cover rounded-lg flex-shrink-0 shadow">`
          : `<div class="w-16 h-24 bg-gray-700 rounded-lg flex-shrink-0"></div>`
        }
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2 flex-wrap mb-1">
            ${data.media_type === 'tv'
              ? '<span class="text-xs px-2 py-0.5 rounded-full bg-purple-600/30 text-purple-400 border border-purple-600/30">TV Show</span>'
              : '<span class="text-xs px-2 py-0.5 rounded-full bg-blue-600/30 text-blue-400 border border-blue-600/30">Movie</span>'
            }
            ${data.streaming_service ? `<span class="text-xs text-teal-400">${this.escapeHtml(data.streaming_service)}</span>` : ''}
          </div>
          <p class="text-white font-semibold">${this.escapeHtml(data.title || '')}</p>
          ${data.vote_average ? `<p class="text-yellow-400 text-xs mt-0.5">★ ${parseFloat(data.vote_average).toFixed(1)}</p>` : ''}
          ${data.overview ? `<p class="text-gray-400 text-xs mt-1 line-clamp-2">${this.escapeHtml(data.overview)}</p>` : ''}
          ${data.cast ? `<p class="text-gray-500 text-xs mt-1">Starring: ${this.escapeHtml(data.cast)}</p>` : ''}
        </div>
      </div>
    `
    preview.classList.remove("hidden")
  }

  hidePreview() {
    const preview = document.getElementById("url_enrich_preview")
    if (preview) { preview.innerHTML = ""; preview.classList.add("hidden") }
  }

  showSpinner() {
    const el = document.getElementById("url_enrich_spinner")
    if (el) el.classList.remove("hidden")
  }

  hideSpinner() {
    const el = document.getElementById("url_enrich_spinner")
    if (el) el.classList.add("hidden")
  }

  showError(msg) {
    const el = document.getElementById("url_enrich_error")
    if (el) { el.textContent = msg; el.classList.remove("hidden") }
  }

  hideError() {
    const el = document.getElementById("url_enrich_error")
    if (el) { el.textContent = ""; el.classList.add("hidden") }
  }

  isValidUrl(str) {
    try { new URL(str); return true } catch { return false }
  }

  escapeHtml(str) {
    return String(str).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
