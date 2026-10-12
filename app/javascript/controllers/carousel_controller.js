import { Controller } from "@hotwired/stimulus"

// Swipeable slides using CSS scroll-snap. Swiping is native; the arrows,
// the stops row and the keyboard's ← → keys move between slides too.
export default class extends Controller {
  static targets = ["track", "slide", "stop", "prev", "next"]

  connect() {
    this.index = 0

    // Whichever slide is mostly visible is the current one (covers swiping)
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) this.select(this.slideTargets.indexOf(entry.target))
      })
    }, { root: this.trackTarget, threshold: 0.6 })

    this.slideTargets.forEach((slide) => this.observer.observe(slide))
    this.update()
  }

  disconnect() {
    this.observer?.disconnect()
  }

  previous() {
    this.go(this.index - 1)
  }

  next() {
    this.go(this.index + 1)
  }

  jump(event) {
    this.go(Number(event.params.index))
  }

  keydown(event) {
    if (event.target.closest("input, textarea")) return
    if (event.key === "ArrowRight") { event.preventDefault(); this.next() }
    if (event.key === "ArrowLeft") { event.preventDefault(); this.previous() }
  }

  go(index) {
    const slide = this.slideTargets[index]
    if (!slide) return

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.trackTarget.scrollTo({ left: slide.offsetLeft, behavior: reduceMotion ? "auto" : "smooth" })
    this.select(index)
  }

  select(index) {
    if (index < 0 || index === this.index) return
    this.index = index
    this.update()
    this.stopTargets[index]?.scrollIntoView({ block: "nearest", inline: "center", behavior: "smooth" })
  }

  update() {
    this.slideTargets.forEach((slide, i) => { slide.inert = i !== this.index })
    this.stopTargets.forEach((stop, i) => stop.setAttribute("aria-current", i === this.index ? "true" : "false"))
    if (this.hasPrevTarget) this.prevTarget.disabled = this.index === 0
    if (this.hasNextTarget) this.nextTarget.disabled = this.index === this.slideTargets.length - 1
  }
}
