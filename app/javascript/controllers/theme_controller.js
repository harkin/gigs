import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["swatch", "layoutBtn"]

  connect() {
    const savedTheme = localStorage.getItem("theme") || "light"
    const isMobile = window.matchMedia("(max-width: 767px)").matches
    const savedLayout = isMobile ? "cards" : (localStorage.getItem("layout") || "list")
    this.applyTheme(savedTheme)
    this.applyLayout(savedLayout)
  }

  select(event) {
    const theme = event.currentTarget.dataset.themeValue
    this.applyTheme(theme)
    localStorage.setItem("theme", theme)
  }

  toggleLayout(event) {
    const layout = event.currentTarget.dataset.layoutValue
    this.applyLayout(layout)
    localStorage.setItem("layout", layout)
  }

  applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme)

    this.swatchTargets.forEach(swatch => {
      swatch.classList.toggle("active", swatch.dataset.themeValue === theme)
    })
  }

  applyLayout(layout) {
    const tableLayout = document.querySelector('[data-layout="table"]')
    const cardsLayout = document.querySelector('[data-layout="cards"]')
    if (tableLayout && cardsLayout) {
      if (layout === "cards") {
        tableLayout.classList.add("hidden")
        cardsLayout.classList.remove("hidden")
      } else {
        tableLayout.classList.remove("hidden")
        cardsLayout.classList.add("hidden")
      }
    }

    this.layoutBtnTargets.forEach(btn => {
      btn.classList.toggle("active", btn.dataset.layoutValue === layout)
    })
  }
}
