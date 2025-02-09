import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount"]

  connect() {
    this.element.addEventListener("turbo:submit-end", this.handleSubmission.bind(this))
  }

  handleSubmission(event) {
    if (event.detail.success) {
      this.amountTarget.value = ""
    }
  }
} 