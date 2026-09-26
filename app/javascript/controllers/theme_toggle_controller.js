import { Controller } from "@hotwired/stimulus"

// With no stored choice the page follows the OS setting; the layout's inline
// script applies a stored choice before first paint.
export default class extends Controller {
  toggle() {
    const root = document.documentElement
    const current = root.dataset.theme || (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
    const next = current === "dark" ? "light" : "dark"
    root.dataset.theme = next
    try { localStorage.setItem("redesign-theme", next) } catch (e) {}
  }
}
