import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "bar", "search", "when", "newOnly", "hideSold",
    "venueButton", "venueLabel", "venueMenu", "venueCheckbox",
    "row", "day", "onNow", "onNowCount", "count", "empty"
  ]
  static values = { today: String }

  connect() {
    this.when = "all"
    this.barObserver = new ResizeObserver(() => this.syncBarHeight())
    this.barObserver.observe(this.barTarget)
    document.addEventListener("click", this.handleOutsideClick)
    document.addEventListener("keydown", this.handleKeydown)
    this.filter()
  }

  disconnect() {
    this.barObserver.disconnect()
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
  }

  // Day headers stick just below the filter bar, whose height changes as
  // the chips wrap.
  syncBarHeight() {
    document.documentElement.style.setProperty("--bar-h", `${this.barTarget.offsetHeight}px`)
  }

  selectWhen(event) {
    this.when = event.currentTarget.dataset.when
    this.whenTargets.forEach(chip => chip.setAttribute("aria-pressed", chip === event.currentTarget))
    this.filter()
  }

  toggle(event) {
    const chip = event.currentTarget
    chip.setAttribute("aria-pressed", chip.getAttribute("aria-pressed") !== "true")
    this.filter()
  }

  toggleVenueMenu() {
    this.setVenueMenuOpen(this.venueMenuTarget.hidden)
  }

  setVenueMenuOpen(open) {
    this.venueMenuTarget.hidden = !open
    this.venueButtonTarget.setAttribute("aria-expanded", open)
  }

  handleOutsideClick = (event) => {
    if (!this.venueMenuTarget.contains(event.target) && !this.venueButtonTarget.contains(event.target)) {
      this.setVenueMenuOpen(false)
    }
  }

  handleKeydown = (event) => {
    if (event.key === "Escape" && !this.venueMenuTarget.hidden) {
      this.setVenueMenuOpen(false)
      this.venueButtonTarget.focus()
    }
  }

  clearVenues() {
    this.venueCheckboxTargets.forEach(box => { box.checked = false })
    this.filter()
  }

  reset() {
    this.searchTarget.value = ""
    this.when = "all"
    this.whenTargets.forEach(chip => chip.setAttribute("aria-pressed", chip.dataset.when === "all"))
    this.newOnlyTarget.setAttribute("aria-pressed", false)
    this.hideSoldTarget.setAttribute("aria-pressed", false)
    this.clearVenues()
  }

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()
    const venues = new Set(this.venueCheckboxTargets.filter(box => box.checked).map(box => box.value))
    const newOnly = this.newOnlyTarget.getAttribute("aria-pressed") === "true"
    const hideSold = this.hideSoldTarget.getAttribute("aria-pressed") === "true"
    const [from, to] = this.dateRange()

    this.updateVenueLabel(venues)

    let visible = 0
    this.rowTargets.forEach(row => {
      const { start, end, search, venue } = row.dataset
      const show = (!query || search.includes(query)) &&
        (venues.size === 0 || venues.has(venue)) &&
        (!newOnly || row.dataset.new === "true") &&
        (!hideSold || row.dataset.sold !== "true") &&
        start <= to && end >= from
      row.hidden = !show
      if (show) visible++
    })

    this.dayTargets.forEach(day => {
      const count = day.querySelectorAll(".row:not([hidden])").length
      day.hidden = count === 0
      day.querySelector("[data-count]").textContent = count
      day.querySelector("[data-noun]").textContent = count === 1 ? "gig" : "gigs"
    })

    if (this.hasOnNowTarget) {
      const count = this.onNowTarget.querySelectorAll(".row:not([hidden])").length
      this.onNowTarget.hidden = count === 0
      this.onNowCountTarget.textContent = count
    }

    this.countTarget.textContent = visible.toLocaleString("en-IE")
    this.emptyTarget.hidden = visible > 0
  }

  // ISO date strings compare correctly as plain strings, so rows are matched
  // on whether their [start, end] overlaps the chosen range.
  dateRange() {
    const today = this.todayValue
    switch (this.when) {
      case "today": return [today, today]
      case "tomorrow": return [this.addDays(today, 1), this.addDays(today, 1)]
      case "week": return [today, this.addDays(today, 6)]
      case "weekend": {
        const weekday = new Date(`${today}T12:00:00Z`).getUTCDay()
        const toSunday = (7 - weekday) % 7
        const toFriday = weekday === 0 || weekday >= 5 ? 0 : 5 - weekday
        return [this.addDays(today, toFriday), this.addDays(today, toSunday)]
      }
      default: return ["", "9999-12-31"]
    }
  }

  addDays(iso, days) {
    const date = new Date(`${iso}T12:00:00Z`)
    date.setUTCDate(date.getUTCDate() + days)
    return date.toISOString().slice(0, 10)
  }

  updateVenueLabel(venues) {
    let label = "All venues"
    if (venues.size === 1) {
      label = this.venueCheckboxTargets.find(box => box.checked).closest("label").textContent.trim()
    } else if (venues.size > 1) {
      label = `${venues.size} venues`
    }
    this.venueLabelTarget.textContent = label
    this.venueButtonTarget.title = label
  }
}
