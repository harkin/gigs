import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "search", "venueButton", "venueLabel", "venueMenu", "venueCheckbox",
    "dateFrom", "dateTo", "row", "count", "noResults"
  ]

  connect() {
    this.filter()

    // Re-apply filters when Turbo Frame content changes (layout switch)
    document.addEventListener("turbo:frame-load", this.handleFrameLoad)
    document.addEventListener("click", this.handleOutsideClick)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.handleFrameLoad)
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleFrameLoad = (event) => {
    if (event.target.id === "events-display") {
      this.filter()
    }
  }

  handleOutsideClick = (event) => {
    if (!this.venueMenuTarget.contains(event.target) && !this.venueButtonTarget.contains(event.target)) {
      this.closeVenueMenu()
    }
  }

  handleKeydown = (event) => {
    if (event.key === "Escape" && !this.venueMenuTarget.classList.contains("hidden")) {
      this.closeVenueMenu()
      this.venueButtonTarget.focus()
    }
  }

  toggleVenueMenu() {
    const opening = this.venueMenuTarget.classList.contains("hidden")
    this.venueMenuTarget.classList.toggle("hidden", !opening)
    this.venueButtonTarget.setAttribute("aria-expanded", opening)
    if (opening) this.sizeVenueMenu()
  }

  // Sized on open, not in CSS: the button's distance from the top of the
  // viewport changes as the sticky filter bar scrolls.
  sizeVenueMenu() {
    const spaceBelow = window.innerHeight - this.venueButtonTarget.getBoundingClientRect().bottom
    this.venueMenuTarget.style.maxHeight = `${Math.max(spaceBelow - 24, 200)}px`
  }

  closeVenueMenu() {
    this.venueMenuTarget.classList.add("hidden")
    this.venueButtonTarget.setAttribute("aria-expanded", "false")
  }

  clearVenues() {
    this.uncheckVenues()
    this.filter()
  }

  uncheckVenues() {
    this.venueCheckboxTargets.forEach(box => { box.checked = false })
  }

  updateVenueLabel(selected) {
    let label
    if (selected.size === 0) {
      label = "All Venues"
    } else if (selected.size === 1) {
      label = this.venueCheckboxTargets.find(box => box.checked).closest("label").textContent.trim()
    } else {
      label = `${selected.size} venues`
    }

    this.venueLabelTarget.textContent = label
    // Long venue names are ellipsised by .venue-button-label
    this.venueButtonTarget.title = label
  }

  filter() {
    const searchTerm = this.searchTarget.value.toLowerCase().trim()
    const selectedVenues = new Set(
      this.venueCheckboxTargets.filter(box => box.checked).map(box => box.value)
    )
    this.updateVenueLabel(selectedVenues)
    const dateFrom = this.dateFromTarget.value ? new Date(this.dateFromTarget.value) : null
    const dateTo = this.dateToTarget.value ? new Date(this.dateToTarget.value + "T23:59:59") : null

    let visibleCount = 0

    this.rowTargets.forEach(row => {
      const title = row.dataset.title.toLowerCase()
      const venue = row.dataset.venue
      const eventDate = new Date(row.dataset.date)

      const matchesSearch = !searchTerm || title.includes(searchTerm)
      const matchesVenue = selectedVenues.size === 0 || selectedVenues.has(venue)
      const matchesDateFrom = !dateFrom || eventDate >= dateFrom
      const matchesDateTo = !dateTo || eventDate <= dateTo

      const isVisible = matchesSearch && matchesVenue && matchesDateFrom && matchesDateTo

      row.classList.toggle("hidden", !isVisible)
      if (isVisible) visibleCount++
    })

    this.countTarget.textContent = visibleCount
    this.noResultsTargets.forEach(el => {
      el.classList.toggle("hidden", visibleCount > 0)
    })
  }

  reset() {
    this.searchTarget.value = ""
    this.uncheckVenues()
    this.dateFromTarget.value = ""
    this.dateToTarget.value = ""
    this.filter()
  }
}
