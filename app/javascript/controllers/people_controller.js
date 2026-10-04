import { Controller } from "@hotwired/stimulus"

const MAX_PEOPLE = 8
const MIN_PEOPLE = 2

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    if (this.listTarget.children.length >= MAX_PEOPLE) return

    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML)
    this.listTarget.lastElementChild.querySelector("input[type=text]")?.focus()
  }

  remove(event) {
    if (this.listTarget.children.length <= MIN_PEOPLE) return

    event.target.closest("[data-person]").remove()
  }
}
