import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }
  static targets = [ "input", "section" ]

  sectionTargetConnected() {
    this.#restoreToggles()
  }

  toggle(event) {
    const section = event.target
    if (section.hasAttribute("data-temp-expand")) return
    
    const key = this.#localStorageKey(section)
    section.open
      ? localStorage.removeItem(key)
      : localStorage.setItem(key, true)
  }

  showWhileFiltering() {
    if (this.inputTarget.value) {
      for (const section of this.sectionTargets) {
        section.setAttribute("data-temp-expand", true)
        section.open = true
      }
    } else {
      this.#restoreToggles()
    }
  }

  #restoreToggles() {
    this.sectionTargets.forEach(section => {
      const key = this.#localStorageKey(section)
      section.open = !localStorage.getItem(key)
      section.removeAttribute("data-temp-expand")
    })
  }

  #localStorageKey(section) {
    return section.getAttribute("data-nav-section-expander-key-value")
  }
}
