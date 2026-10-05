import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "value", "list"]
  static values = { url: String, nearestUrl: String }

  connect() {
    this.requestId = 0
  }

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
            button.className = "flex w-full items-baseline justify-between gap-3 px-4 py-3 text-left hover:bg-platform"

      const label = document.createElement("span")
      label.textContent = `${station.name} ${station.romaji ?? ""}`

      const lines = document.createElement("span")
      lines.className = "text-xs text-steel"
      lines.textContent = `${station.lines} ${station.lines === 1 ? "line" : "lines"}`

      button.append(label, lines)
      button.addEventListener("click", () => this.pick(station))
      this.listTarget.append(button)
    })

    this.listTarget.hidden = false
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
  locate() {
    if (!navigator.geolocation) return this.locateFailed("Location isn't available in this browser")

    this.inputTarget.value = ""
    this.valueTarget.value = ""
    this.inputTarget.placeholder = "Finding your nearest station…"

    navigator.geolocation.getCurrentPosition(
      (position) => this.lookUpNearest(position.coords),
      () => this.locateFailed("Couldn't get your location"),
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 }
    )
  }

  async lookUpNearest({ latitude, longitude }) {
    const response = await fetch(`${this.nearestUrlValue}?lat=${latitude}&lon=${longitude}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok) return this.locateFailed("No station within 3 km of you")

    this.pick(await response.json())
    this.inputTarget.placeholder = "Station, e.g. Shibuya or 渋谷"
  }

  locateFailed(message) {
    this.inputTarget.value = ""
    this.inputTarget.placeholder = message
    this.inputTarget.focus()
  }
}
