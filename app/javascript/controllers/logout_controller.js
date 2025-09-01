import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="logout"
export default class extends Controller {
  static targets = ["link"]

  connect() {
    // Add session timeout warning
    this.setupSessionTimeout()
  }

  disconnect() {
    if (this.timeoutWarning) {
      clearTimeout(this.timeoutWarning)
    }
    if (this.forceLogout) {
      clearTimeout(this.forceLogout)
    }
  }

  // Enhanced logout with confirmation
  confirm(event) {
    event.preventDefault()
    
    const link = event.currentTarget
    const confirmMessage = "Are you sure you want to sign out?"
    
    if (confirm(confirmMessage)) {
      this.performLogout(link)
    }
  }

  // Perform the actual logout
  performLogout(link) {
    // Show loading state
    const originalText = link.innerHTML
    link.innerHTML = '<i class="mdi mdi-loading mdi-spin icon-md me-2"></i> Signing out...'
    link.style.pointerEvents = 'none'

    // Get the href from the link (should be /auth/logout)
    const logoutUrl = link.getAttribute('href')
    
    // For our app, we'll redirect to the logout confirmation page first
    // The actual logout happens via the form on that page
    window.location.href = logoutUrl

    // Fallback restore if something fails
    setTimeout(() => {
      link.innerHTML = originalText
      link.style.pointerEvents = 'auto'
    }, 5000)
  }

  // Session timeout management
  setupSessionTimeout() {
    // Warn user 5 minutes before 24-hour session expires
    const sessionDuration = 24 * 60 * 60 * 1000 // 24 hours in milliseconds
    const warningTime = sessionDuration - (5 * 60 * 1000) // 5 minutes before expiry
    
    this.timeoutWarning = setTimeout(() => {
      this.showSessionWarning()
    }, warningTime)
  }

  showSessionWarning() {
    const extendSession = confirm(
      "Your session will expire in 5 minutes. Would you like to extend your session?"
    )
    
    if (extendSession) {
      // Make a request to extend session
      fetch(window.location.href, {
        method: 'HEAD',
        credentials: 'include'
      }).then(() => {
        // Reset timeout
        this.setupSessionTimeout()
      }).catch(() => {
        this.forceLogoutWarning()
      })
    } else {
      this.forceLogoutWarning()
    }
  }

  forceLogoutWarning() {
    alert("You will be automatically logged out in 5 minutes due to inactivity.")
    
    this.forceLogout = setTimeout(() => {
      window.location.href = '/logout'
    }, 5 * 60 * 1000) // 5 minutes
  }

  // Handle activity to reset timeout
  resetTimeout() {
    if (this.timeoutWarning) {
      clearTimeout(this.timeoutWarning)
    }
    if (this.forceLogout) {
      clearTimeout(this.forceLogout)
    }
    this.setupSessionTimeout()
  }
}
