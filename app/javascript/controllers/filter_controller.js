import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "venue", "dateFrom", "dateTo", "row", "count", "noResults"]

  connect() {
    this.filter()
  }

  filter() {
    const searchTerm = this.searchTarget.value.toLowerCase().trim()
    const selectedVenue = this.venueTarget.value
    const dateFrom = this.dateFromTarget.value ? new Date(this.dateFromTarget.value) : null
    const dateTo = this.dateToTarget.value ? new Date(this.dateToTarget.value + "T23:59:59") : null

    // Find the currently visible layout to count only its rows
    const visibleLayout = document.querySelector('[data-layout]:not(.hidden)')
    let visibleCount = 0

    this.rowTargets.forEach(row => {
      const title = row.dataset.title.toLowerCase()
      const venue = row.dataset.venue
      const eventDate = new Date(row.dataset.date)

      const matchesSearch = !searchTerm || title.includes(searchTerm)
      const matchesVenue = !selectedVenue || venue === selectedVenue
      const matchesDateFrom = !dateFrom || eventDate >= dateFrom
      const matchesDateTo = !dateTo || eventDate <= dateTo

      const isVisible = matchesSearch && matchesVenue && matchesDateFrom && matchesDateTo

      row.classList.toggle("hidden", !isVisible)
      if (isVisible && visibleLayout && visibleLayout.contains(row)) visibleCount++
    })

    this.countTarget.textContent = visibleCount
    this.noResultsTargets.forEach(el => {
      el.classList.toggle("hidden", visibleCount > 0)
    })
  }

  reset() {
    this.searchTarget.value = ""
    this.venueTarget.value = ""
    this.dateFromTarget.value = ""
    this.dateToTarget.value = ""
    this.filter()
  }
}
