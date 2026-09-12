import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["swatch", "layoutBtn"]

  connect() {
    const urlParams = new URLSearchParams(window.location.search)
    // Rendered from GigsHelper::THEMES so the list lives in one place
    const themes = document.documentElement.dataset.themes.split(" ")

    // A ?theme= param previews a theme without persisting it
    let savedTheme = urlParams.get("theme")
    if (!themes.includes(savedTheme)) savedTheme = localStorage.getItem("theme")
    if (!themes.includes(savedTheme)) savedTheme = themes[0]
    this.applyTheme(savedTheme)

    // Check if we need to switch to saved layout preference;
    // an explicit ?layout= param wins over the saved one
    const isMobile = window.matchMedia("(max-width: 767px)").matches
    const savedLayout = isMobile ? "cards" : (localStorage.getItem("layout") || "table")
    const currentLayout = document.querySelector("turbo-frame#events-display")?.dataset.currentLayout

    if (!urlParams.has("layout") && currentLayout && savedLayout !== currentLayout) {
      // Trigger Turbo Frame navigation to preferred layout
      const layoutLink = document.querySelector(`a[data-turbo-frame="events-display"][data-layout-value="${savedLayout}"]`)
      if (layoutLink) {
        layoutLink.click()
      }
    }
  }

  select(event) {
    const theme = event.currentTarget.dataset.themeValue
    this.applyTheme(theme)
    localStorage.setItem("theme", theme)
  }

  selectLayout(event) {
    const layout = event.currentTarget.dataset.layoutValue
    localStorage.setItem("layout", layout)
    this.updateLayoutButtons(layout)
  }

  applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme)

    this.swatchTargets.forEach(swatch => {
      swatch.classList.toggle("active", swatch.dataset.themeValue === theme)
    })
  }

  updateLayoutButtons(layout) {
    this.layoutBtnTargets.forEach(btn => {
      btn.classList.toggle("active", btn.dataset.layoutValue === layout)
    })
  }
}
