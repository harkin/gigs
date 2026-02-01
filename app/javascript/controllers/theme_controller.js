import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["swatch"]

  connect() {
    const saved = localStorage.getItem("theme") || "bold"
    this.applyTheme(saved)
  }

  select(event) {
    const theme = event.currentTarget.dataset.themeValue
    this.applyTheme(theme)
    localStorage.setItem("theme", theme)
  }

  applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme)

    // Toggle table vs cards layout visibility
    const tableLayout = document.querySelector('[data-layout="table"]')
    const cardsLayout = document.querySelector('[data-layout="cards"]')
    if (tableLayout && cardsLayout) {
      if (theme === "cards") {
        tableLayout.classList.add("hidden")
        cardsLayout.classList.remove("hidden")
      } else {
        tableLayout.classList.remove("hidden")
        cardsLayout.classList.add("hidden")
      }
    }

    // Update active swatch indicator
    this.swatchTargets.forEach(swatch => {
      const isActive = swatch.dataset.themeValue === theme
      swatch.style.boxShadow = isActive ? "0 0 0 3px var(--bg), 0 0 0 5px var(--accent)" : "none"
      swatch.style.transform = isActive ? "scale(1.15)" : ""
    })
  }
}
