import { Controller } from "@hotwired/stimulus"

const FALLBACK_COLOR = "#5d6876"
const DEFAULT_PLACEHOLDER = "station, e.g. shibuya or 渋谷"

export default class extends Controller {
  static targets = ["input", "value", "list"]
  static values = { url: String, nearestUrl: String }

  connect() {
    this.requestId = 0
  }

  // --- Autocomplete ---

  search() {
    this.valueTarget.value = "" // typing again clears any previous pick
    clearTimeout(this.timer)

    const query = this.inputTarget.value.trim()
    if (!query) return this.close()

    this.timer = setTimeout(() => this.fetchResults(query), 150)
  }

  async fetchResults(query) {
    const id = ++this.requestId
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok || id !== this.requestId) return // ignore failed or outdated responses

    this.render(await response.json())
  }

  render(stations) {
    this.listTarget.replaceChildren()
    if (stations.length === 0) return this.close()

    stations.forEach((station) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "flex w-full items-center justify-between gap-3 px-4 py-3 text-left hover:bg-platform"

      const label = document.createElement("span")
      label.className = "min-w-0 truncate"
      label.textContent = `${station.name} ${station.romaji ?? ""}`

      button.append(label, this.badgesFor(station))
      button.addEventListener("click", () => this.pick(station))
      this.listTarget.append(button)
    })

    this.listTarget.hidden = false
  }

  badgesFor(station) {
    const badges = document.createElement("span")
    badges.className = "flex shrink-0 items-center gap-1"
    const list = station.badges || []

    list.forEach((badge) => {
      const pill = document.createElement("span")
      pill.className = "inline-flex h-6 min-w-6 items-center justify-center rounded-full border-2 bg-sign px-1 text-[10px] font-bold leading-none text-ink"
      pill.style.borderColor = badge.color || FALLBACK_COLOR
      pill.textContent = badge.letters || ""
      pill.setAttribute("aria-hidden", "true")
      badges.append(pill)
    })

    if (station.lines > list.length) {
      const more = document.createElement("span")
      more.className = "text-xs text-steel"
      more.textContent = `+${station.lines - list.length}`
      more.setAttribute("aria-hidden", "true")
      badges.append(more)
    }

    return badges
  }

  pick(station) {
    this.inputTarget.value = `${station.name} ${station.romaji ?? ""}`.trim()
    this.valueTarget.value = station.group_code
    this.close()
  }

  close() {
    this.listTarget.hidden = true
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  // --- Use my location ---

  locate() {
    if (!navigator.geolocation) return this.locateFailed("location isn't available in this browser")

    this.close()
    this.inputTarget.value = ""
    this.valueTarget.value = ""
    this.inputTarget.placeholder = "finding your nearest station…"

    navigator.geolocation.getCurrentPosition(
      (position) => this.lookUpNearest(position.coords),
      () => this.locateFailed("couldn't get your location"),
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 }
    )
  }

  async lookUpNearest({ latitude, longitude }) {
    const response = await fetch(`${this.nearestUrlValue}?lat=${latitude}&lon=${longitude}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok) return this.locateFailed("no station within 3 km of you")

    this.pick(await response.json())
    this.inputTarget.placeholder = DEFAULT_PLACEHOLDER
  }

  locateFailed(message) {
    this.inputTarget.value = ""
    this.inputTarget.placeholder = message
    this.inputTarget.focus()
  }
}
