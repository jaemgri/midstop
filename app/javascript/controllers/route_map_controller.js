import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

const INK = "#1b2533"
const TACTILE = "#f4c300"

export default class extends Controller {
  static values = { data: Object }

  connect() {
    const { meeting, people } = this.dataValue

    this.map = L.map(this.element, { scrollWheelZoom: false, zoomControl: false })

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    const bounds = L.latLngBounds([meeting.coords])

    people.forEach((person) => {
      if (person.path.length === 0) return

      L.polyline(person.path, { color: INK, weight: 3, opacity: 0.5 }).addTo(this.map)

      L.circleMarker(person.path[0], { radius: 6, color: INK, weight: 2, fillColor: "#ffffff", fillOpacity: 1 })
        .bindTooltip(person.name, { permanent: true, direction: "top", offset: [0, -6], className: "map-label" })
        .addTo(this.map)

      person.path.forEach((point) => bounds.extend(point))
    })

    L.circleMarker(meeting.coords, { radius: 10, color: INK, weight: 3, fillColor: TACTILE, fillOpacity: 1 })
      .bindTooltip(meeting.romaji || meeting.name, { permanent: true, direction: "top", offset: [0, -10], className: "map-label map-label-meet" })
      .addTo(this.map)

    this.map.fitBounds(bounds, { padding: [32, 32] })
  }

  disconnect() {
    this.map?.remove()
  }
}
