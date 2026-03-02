import { Controller } from "@hotwired/stimulus"

const SERVICES = {
  "netflix.com": "Netflix",
  "max.com": "Max",
  "hbo.com": "Max",
  "disneyplus.com": "Disney+",
  "hulu.com": "Hulu",
  "primevideo.com": "Prime Video",
  "amazon.com": "Prime Video",
  "tv.apple.com": "Apple TV+",
  "apple.com/apple-tv-plus": "Apple TV+",
  "peacocktv.com": "Peacock",
  "paramountplus.com": "Paramount+",
  "mubi.com": "MUBI",
  "shudder.com": "Shudder",
  "youtube.com": "YouTube"
}

export default class extends Controller {
  detect(event) {
    const url = event.target.value.trim()
    if (!url) return

    for (const [domain, service] of Object.entries(SERVICES)) {
      if (url.includes(domain)) {
        const serviceField = document.getElementById("streaming_service_field")
        if (serviceField && !serviceField.value) {
          serviceField.value = service
        }
        break
      }
    }
  }
}
