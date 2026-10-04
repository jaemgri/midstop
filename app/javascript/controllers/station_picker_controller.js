import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "value", "list"]
  static values = { url: String }

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
      button.className = "flex w-full items-baseline justify-between gap-3 px-4 py-2 text-left hover:bg-gray-100"

      const label = document.createElement("span")
      label.textContent = `${station.name} ${station.romaji ?? ""}`

      const lines = document.createElement("span")
      lines.className = "text-xs text-gray-500"
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
}
