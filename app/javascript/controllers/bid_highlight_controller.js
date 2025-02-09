import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const currentUserId = this.element.closest('[data-bid-highlight-user-id-value]')?.dataset.bidHighlightUserIdValue
    const bidUserId = this.element.dataset.bidUserId

    if (currentUserId && bidUserId && currentUserId === bidUserId) {
      this.element.classList.remove('bg-gray-50', 'hover:bg-gray-100')
      this.element.classList.add('bg-green-50', 'hover:bg-green-100')
      
      const avatar = this.element.querySelector('.rounded-full')
      if (avatar) {
        avatar.classList.remove('bg-indigo-100')
        avatar.classList.add('bg-green-100')
      }

      const initial = avatar.querySelector('span')
      if (initial) {
        initial.classList.remove('text-indigo-600')
        initial.classList.add('text-green-600')
      }

      const amount = this.element.querySelector('.font-semibold')
      if (amount) {
        amount.classList.remove('text-indigo-600')
        amount.classList.add('text-green-600')
      }
    }
  }
} 