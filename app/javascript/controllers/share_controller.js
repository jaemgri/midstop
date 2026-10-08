import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["share", "copy"]
  static values = { url: String, title: String, text: String, copied: String, failed: String }

  connect() {
    this.copyLabel = this.copyTarget.textContent

    // Phones and Safari have a share sheet; elsewhere, fall back to copying the link.
    if (navigator.share) {
      this.shareTarget.hidden = false
      this.copyTarget.hidden = true
    }
  }

  async share() {
    try {
      await navigator.share({ title: this.titleValue, text: this.textValue, url: this.urlValue })
    } catch (error) {
      if (error.name !== "AbortError") console.error(error)
    }
  }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.urlValue)
      this.copyTarget.textContent = this.copiedValue || "Link copied"
    } catch (error) {
      console.error(error)
      this.copyTarget.textContent = this.failedValue || "Couldn't copy"
    }
    clearTimeout(this.timer)
    this.timer = setTimeout(() => (this.copyTarget.textContent = this.copyLabel), 2000)
  }
}
