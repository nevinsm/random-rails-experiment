import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  selectAll() {
    this.checkboxTargets.forEach(cb => { cb.checked = true })
  }

  selectNone() {
    this.checkboxTargets.forEach(cb => { cb.checked = false })
  }
}


