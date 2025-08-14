import { Controller } from "@hotwired/stimulus"

const BOTTOM_THRESHOLD = 90

export default class extends Controller {
  static targets = [ "dialog" ]
  static values = {
    modal: { type: Boolean, default: false }
  }

  connect() {
    this.dialogTarget.setAttribute('aria-hidden', 'true')
  }

  open() {
    const modal = this.modalValue

    if (modal) {
      this.dialogTarget.showModal()
    } else {
      this.dialogTarget.show()
    }
    this.#orient()
    this.dialogTarget.setAttribute('aria-hidden', 'false')
    this.dispatch("show")
  }

  toggle() {
    if (this.dialogTarget.open) {
      this.close()
    } else {
      this.open()
    }
  }

  close() {
    this.dialogTarget.close()
    this.dialogTarget.setAttribute('aria-hidden', 'true')
    this.dialogTarget.blur()
  }

  closeOnClickOutside({ target }) {
    if (!this.element.contains(target)) this.close()
  }

  #orient() {
    console.log("ORIENT")
    console.log(`distanceToBottom = ${this.#distanceToBottom}`)
    console.log(`maxWidth = ${this.#maxWidth}px`)

    this.dialogTarget.classList.toggle("ANDYSMITH", this.#distanceToBottom < BOTTOM_THRESHOLD)
    this.dialogTarget.style.setProperty("--max-width", this.#maxWidth + "px")
  }

  get #distanceToBottom() {
    return window.innerHeight - this.#boundingClientRect.bottom
  }

  get #maxWidth() {
    return window.innerWidth - this.#boundingClientRect.left
  }

  get #boundingClientRect() {
    return this.dialogTarget.getBoundingClientRect()
  }
}
