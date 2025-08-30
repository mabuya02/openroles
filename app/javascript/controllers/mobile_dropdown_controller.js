import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    this.setupMobileDropdowns()
  }

  setupMobileDropdowns() {
    // Only apply mobile behavior on screens smaller than lg breakpoint
    if (window.innerWidth < 992) {
      this.enableMobileDropdowns()
    }

    // Listen for window resize to toggle behavior
    window.addEventListener('resize', () => {
      if (window.innerWidth < 992) {
        this.enableMobileDropdowns()
      } else {
        this.disableMobileDropdowns()
      }
    })
  }

  enableMobileDropdowns() {
    const dropdowns = document.querySelectorAll('.topnav-menu .navbar-nav .nav-item.dropdown')
    
    dropdowns.forEach(dropdown => {
      const toggle = dropdown.querySelector('.nav-link, .dropdown-item.dropdown-toggle')
      const menu = dropdown.querySelector('.dropdown-menu')
      
      if (toggle && menu) {
        // Remove Bootstrap dropdown behavior
        toggle.removeAttribute('data-bs-toggle')
        
        // Add click handler for accordion behavior
        toggle.addEventListener('click', (e) => {
          e.preventDefault()
          e.stopPropagation()
          
          // Close other dropdowns at the same level
          this.closeOtherDropdowns(dropdown)
          
          // Toggle current dropdown
          dropdown.classList.toggle('show')
        })
      }
    })
  }

  disableMobileDropdowns() {
    const dropdowns = document.querySelectorAll('.topnav-menu .navbar-nav .nav-item.dropdown')
    
    dropdowns.forEach(dropdown => {
      const toggle = dropdown.querySelector('.nav-link, .dropdown-item.dropdown-toggle')
      
      if (toggle) {
        // Restore Bootstrap dropdown behavior
        toggle.setAttribute('data-bs-toggle', 'dropdown')
        dropdown.classList.remove('show')
        
        // Remove custom click handlers
        toggle.removeEventListener('click', this.handleClick)
      }
    })
  }

  closeOtherDropdowns(currentDropdown) {
    const parentLevel = currentDropdown.closest('.dropdown-menu') ? 'nested' : 'main'
    
    if (parentLevel === 'main') {
      // Close all main level dropdowns
      const mainDropdowns = document.querySelectorAll('.topnav-menu .navbar-nav > .nav-item.dropdown')
      mainDropdowns.forEach(dropdown => {
        if (dropdown !== currentDropdown) {
          dropdown.classList.remove('show')
        }
      })
    } else {
      // Close sibling nested dropdowns
      const parentMenu = currentDropdown.closest('.dropdown-menu')
      const siblingDropdowns = parentMenu.querySelectorAll('.dropdown')
      siblingDropdowns.forEach(dropdown => {
        if (dropdown !== currentDropdown) {
          dropdown.classList.remove('show')
        }
      })
    }
  }

  handleClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    
    const dropdown = e.target.closest('.dropdown')
    this.closeOtherDropdowns(dropdown)
    dropdown.classList.toggle('show')
  }
}
