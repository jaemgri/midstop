import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

export default class extends Controller {
  static values = { data: Object }

  connect() {
    const { meeting, people } = this.dataValue
    const css = getComputedStyle(document.documentElement)
    const token = (name, fallback) => css.getPropertyValue(name).trim() || fallback
    this.colors = {
      ink: token("--color-ink", "#1b2533"),
      sign: token("--color-sign", "#ffffff"),
      tactile: token("--color-tactile", "#f4c300"),
      onTactile: token("--color-on-tactile", "#1b2533")
    }

    this.map = L.map(this.element, { scrollWheelZoom: false, zoomControl: false })

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    const bounds = L.latLngBounds([meeting.coords])

    people.forEach((person) => {
      this.drawLegs(person.legs, bounds)
      this.drawTransfers(person.legs)

      L.circleMarker(person.start, {
        radius: 6, color: this.colors.ink, weight: 2, fillColor: this.colors.sign, fillOpacity: 1
      })
        .bindTooltip(person.name, { permanent: true, direction: "top", offset: [0, -6], className: "map-label" })
        .addTo(this.map)
      bounds.extend(person.start)
    })

    L.circleMarker(meeting.coords, {
      radius: 10, color: this.colors.onTactile, weight: 3, fillColor: this.colors.tactile, fillOpacity: 1
    })
      .bindTooltip(meeting.romaji || meeting.name, { permanent: true, direction: "top", offset: [0, -10], className: "map-label map-label-meet" })
      .addTo(this.map)

    this.map.fitBounds(bounds, { padding: [32, 32] })
  }

  // Each leg in its line's colour, over a casing so it stands out from the map
  drawLegs(legs, bounds) {
    legs.forEach((leg) => {
      L.polyline(leg.points, { color: this.colors.sign, weight: 9, opacity: 0.9, lineCap: "round", lineJoin: "round" })
        .addTo(this.map)

      const line = L.polyline(leg.points, { color: leg.color, weight: 5, opacity: 1, lineCap: "round", lineJoin: "round" })
        .addTo(this.map)
      if (leg.name) line.bindTooltip(leg.name, { sticky: true, className: "map-label" })

      leg.points.forEach((point) => bounds.extend(point))
    })
  }

  // Small dots where someone changes from one train to another
  drawTransfers(legs) {
    legs.slice(1).forEach((leg) => {
      L.circleMarker(leg.points[0], {
        radius: 4, color: this.colors.ink, weight: 2, fillColor: this.colors.sign, fillOpacity: 1
      }).addTo(this.map)
    })
  }

  disconnect() {
    this.map?.remove()
  }
}
