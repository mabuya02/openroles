import { Controller } from "@hotwired/stimulus"

// Manages the mobile navigation, converting Bootstrap dropdowns into an accordion.
export default class extends Controller {
  static targets = ["dropdownToggle"]

  connect() {
    // Bind the event handler once to ensure the same function reference is used for add/remove
    this.toggleAccordionHandler = this.toggleAccordion.bind(this)
    this.handleResize()
    window.addEventListener("resize", this.handleResize.bind(this))
  }

  disconnect() {
    window.removeEventListener("resize", this.handleResize.bind(this))
    this.deactivateMobileNav()
  }

  handleResize() {
    if (window.innerWidth < 992) {
      this.activateMobileNav()
    } else {
      this.deactivateMobileNav()
    }
  }

  // Sets up custom click handlers for mobile view
  activateMobileNav() {
    this.dropdownToggleTargets.forEach(toggle => {
      if (!toggle.dataset.originalBsToggle) {
        toggle.dataset.originalBsToggle = toggle.getAttribute("data-bs-toggle")
      }
      toggle.removeAttribute("data-bs-toggle")
      toggle.addEventListener("click", this.toggleAccordionHandler)
    })
  }

  // Restores default Bootstrap behavior for desktop view
  deactivateMobileNav() {
    this.dropdownToggleTargets.forEach(toggle => {
      if (toggle.dataset.originalBsToggle) {
        toggle.setAttribute("data-bs-toggle", toggle.dataset.originalBsToggle)
        toggle.removeAttribute('data-original-bs-toggle')
      }
      toggle.removeEventListener("click", this.toggleAccordionHandler)
    });

    // Close any menus that were left open from mobile view
    this.element.querySelectorAll(".dropdown-menu.show").forEach(menu => {
      menu.classList.remove("show")
    })
  }

  toggleAccordion(event) {
    event.preventDefault()
    event.stopPropagation()

    const toggle = event.currentTarget
    // The menu is expected to be the next sibling element
    const menu = toggle.nextElementSibling

    if (!menu || !menu.classList.contains("dropdown-menu")) {
      console.error("Dropdown menu not found for toggle:", toggle)
      return
    }

    const wasOpen = menu.classList.contains("show")

    // Find the parent list to identify siblings
    const parentList = toggle.closest(".navbar-nav, .dropdown-menu")

    // Close all open menus at the current level
    if (parentList) {
      const openMenus = parentList.querySelectorAll(":scope > .dropdown > .dropdown-menu.show")
      openMenus.forEach(openMenu => {
        openMenu.classList.remove("show")
      })
    }

    // If the clicked menu was closed, open it.
    if (!wasOpen) {
      menu.classList.add("show")
    }
  }
}

