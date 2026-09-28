import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "bar", "search", "chips", "when", "newOnly", "hideSold",
    "venueButton", "venueLabel", "venueMenu", "venueCheckbox",
    "dateChip", "dateLabel", "calendar", "calendarMonth", "calendarGrid", "calendarHint", "prevMonth", "nextMonth",
    "row", "day", "onNow", "onNowCount", "onNowNoun", "count", "empty"
  ]
  static values = { today: String }

  connect() {
    this.when = "all"
    this.range = null
    this.anchor = null
    this.gigsByDay = {}
    this.lastDay = this.rowTargets.reduce((last, row) => row.dataset.start > last ? row.dataset.start : last, this.todayValue)
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
    this.setWhen(event.currentTarget.dataset.when)
    this.clearRange()
    this.setCalendarOpen(false)
    this.filter()
  }

  setWhen(when) {
    this.when = when
    this.whenTargets.forEach(chip => chip.setAttribute("aria-pressed", chip.dataset.when === when))
    this.newOnlyTarget.setAttribute("aria-pressed", false)
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
    if (open) this.setCalendarOpen(false)
    this.venueMenuTarget.hidden = !open
    this.venueButtonTarget.setAttribute("aria-expanded", open)
  }

  toggleCalendar() {
    this.setCalendarOpen(this.calendarTarget.hidden)
  }

  closeCalendar() {
    this.setCalendarOpen(false)
    this.dateChipTarget.focus()
  }

  setCalendarOpen(open) {
    if (open === !this.calendarTarget.hidden) return
    if (open) {
      this.setVenueMenuOpen(false)
      this.month = (this.range?.from ?? this.todayValue).slice(0, 7)
    }
    this.anchor = null
    this.calendarTarget.hidden = !open
    this.dateChipTarget.setAttribute("aria-expanded", open)
    if (open) {
      this.renderCalendar()
      this.positionCalendar()
    }
  }

  // The chip row scrolls sideways, so the popover lives in the bar and is
  // lined up with the chip here.
  positionCalendar() {
    const wrap = this.calendarTarget.offsetParent.getBoundingClientRect()
    const chip = this.dateChipTarget.getBoundingClientRect()
    const maxLeft = wrap.width - this.calendarTarget.offsetWidth - 16
    this.calendarTarget.style.left = `${Math.max(16, Math.min(chip.left - wrap.left, maxLeft))}px`
  }

  shiftMonth(event) {
    const [year, month] = this.month.split("-").map(Number)
    const date = new Date(Date.UTC(year, month - 1 + Number(event.currentTarget.dataset.step), 1))
    this.month = date.toISOString().slice(0, 7)
    this.renderCalendar()
  }

  // The first tap filters to that day; a second tap extends it to a range.
  pickDate(event) {
    const day = event.currentTarget.dataset.date
    if (this.anchor) {
      this.range = day < this.anchor ? { from: day, to: this.anchor } : { from: this.anchor, to: day }
      this.anchor = null
    } else {
      this.range = { from: day, to: day }
      this.anchor = day
    }
    this.setWhen("custom")
    this.updateDateLabel()
    this.filter()
    if (!this.anchor) this.closeCalendar()
  }

  clearDates() {
    this.clearRange()
    this.setWhen("all")
    this.filter()
  }

  clearRange() {
    this.range = null
    this.anchor = null
    this.updateDateLabel()
    if (!this.calendarTarget.hidden) this.renderCalendar()
  }

  // The click that re-renders the grid detaches its own target, so test the
  // path it bubbled through rather than the live tree.
  handleOutsideClick = (event) => {
    const path = event.composedPath()
    if (!path.includes(this.venueMenuTarget) && !path.includes(this.venueButtonTarget)) {
      this.setVenueMenuOpen(false)
    }
    if (!path.includes(this.calendarTarget) && !path.includes(this.dateChipTarget)) {
      this.setCalendarOpen(false)
    }
  }

  handleKeydown = (event) => {
    if (event.key !== "Escape") return
    if (!this.venueMenuTarget.hidden) {
      this.setVenueMenuOpen(false)
      this.venueButtonTarget.focus()
    } else if (!this.calendarTarget.hidden) {
      this.closeCalendar()
    }
  }

  clearVenues() {
    this.venueCheckboxTargets.forEach(box => { box.checked = false })
    this.filter()
  }

  reset() {
    this.searchTarget.value = ""
    this.setWhen("all")
    this.clearRange()
    this.hideSoldTarget.setAttribute("aria-pressed", false)
    this.clearVenues()
  }

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()
    const venues = new Set(this.venueCheckboxTargets.filter(box => box.checked).map(box => box.value))
    const newOnly = this.newOnlyTarget.getAttribute("aria-pressed") === "true"
    const hideSold = this.hideSoldTarget.getAttribute("aria-pressed") === "true"
    const [from, to] = newOnly ? ["", "9999-12-31"] : this.dateRange()
    this.chipsTarget.classList.toggle("is-overridden", newOnly)

    this.updateVenueLabel(venues)

    let visible = 0
    this.gigsByDay = {}
    this.rowTargets.forEach(row => {
      const { start, end, search, venue } = row.dataset
      const matches = (!query || search.includes(query)) &&
        (venues.size === 0 || venues.has(venue)) &&
        (!newOnly || row.dataset.new === "true") &&
        (!hideSold || row.dataset.sold !== "true")
      if (matches) this.gigsByDay[start] = (this.gigsByDay[start] || 0) + 1
      const show = matches && start <= to && end >= from
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
      this.onNowNounTarget.textContent = count === 1 ? "show" : "shows"
    }

    this.countTarget.textContent = visible.toLocaleString("en-IE")
    this.emptyTarget.hidden = visible > 0
    if (!this.calendarTarget.hidden) this.renderCalendar()
  }

  // ISO date strings compare correctly as plain strings, so rows are matched
  // on whether their [start, end] overlaps the chosen range.
  dateRange() {
    const today = this.todayValue
    switch (this.when) {
      case "today": return [today, today]
      case "tomorrow": return [this.addDays(today, 1), this.addDays(today, 1)]
      case "week": return [today, this.addDays(today, 6)]
      case "custom": return [this.range.from, this.range.to]
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

  // Dots follow the other filters, so picking a venue first shows the days it
  // has something on.
  renderCalendar() {
    const [year, month] = this.month.split("-").map(Number)
    const first = new Date(Date.UTC(year, month - 1, 1))
    const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate()
    const leading = (first.getUTCDay() + 6) % 7
    const { from, to } = this.range || {}
    const focused = this.calendarGridTarget.contains(document.activeElement) ? document.activeElement.dataset.date : null

    this.calendarMonthTarget.textContent = first.toLocaleDateString("en-IE", { month: "long", year: "numeric", timeZone: "UTC" })
    this.prevMonthTarget.disabled = this.month <= this.todayValue.slice(0, 7)
    this.nextMonthTarget.disabled = this.month >= this.lastDay.slice(0, 7)

    // Weeks that are already over can't be picked, so they're left out.
    let startDay = 1
    if (this.month === this.todayValue.slice(0, 7)) {
      startDay = Math.max(1, Number(this.todayValue.slice(8)) - (leading + Number(this.todayValue.slice(8)) - 1) % 7)
    }
    const cells = ["M", "T", "W", "T", "F", "S", "S"].map(d => `<span class="cal-dow" aria-hidden="true">${d}</span>`)
    for (let i = 0; i < (startDay === 1 ? leading : 0); i++) cells.push("<span></span>")
    for (let d = startDay; d <= daysInMonth; d++) {
      const iso = `${this.month}-${String(d).padStart(2, "0")}`
      const gigs = this.gigsByDay[iso] || 0
      const selected = from && iso >= from && iso <= to
      const classes = ["cal-day"]
      if (selected) classes.push("in-range")
      if (iso === from) classes.push("range-start")
      if (iso === to) classes.push("range-end")
      if (iso === this.todayValue) classes.push("today")
      const level = gigs === 0 ? 0 : gigs < 4 ? 1 : gigs < 10 ? 2 : 3
      const label = `${this.longDate(iso)}, ${gigs === 0 ? "no gigs" : gigs === 1 ? "1 gig" : `${gigs} gigs`}`
      cells.push(`<button type="button" class="${classes.join(" ")}" data-date="${iso}" data-level="${level}"` +
        ` aria-pressed="${Boolean(selected)}" aria-label="${label}" data-action="listing#pickDate"` +
        `${iso < this.todayValue ? " disabled" : ""}>${d}</button>`)
    }
    this.calendarGridTarget.innerHTML = cells.join("")
    if (focused) this.calendarGridTarget.querySelector(`[data-date="${focused}"]`)?.focus()
    this.calendarHintTarget.textContent = this.anchor ? "Tap an end date" : ""
  }

  updateDateLabel() {
    let label = "Pick dates"
    if (this.range) {
      const { from, to } = this.range
      const short = (iso, parts) => new Date(`${iso}T12:00:00Z`).toLocaleDateString("en-IE", { ...parts, timeZone: "UTC" })
      if (from === to) {
        label = `${short(from, { weekday: "short" })} ${short(from, { day: "numeric", month: "short" })}`
      } else if (from.slice(0, 7) === to.slice(0, 7)) {
        label = `${short(from, { day: "numeric" })}–${short(to, { day: "numeric", month: "short" })}`
      } else {
        label = `${short(from, { day: "numeric", month: "short" })} – ${short(to, { day: "numeric", month: "short" })}`
      }
    }
    this.dateLabelTarget.textContent = label
  }

  longDate(iso) {
    return new Date(`${iso}T12:00:00Z`).toLocaleDateString("en-IE", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" })
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
