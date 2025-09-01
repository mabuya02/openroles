import { Turbo } from "@hotwired/turbo-rails"

// Global Turbo configuration
export class TurboConfig {
  static init() {
    document.addEventListener("DOMContentLoaded", function() {
      // Configure Turbo to handle forms properly
      Turbo.config.drive.enabled = true
      
      // Disable Turbo for forms with file uploads to prevent issues
      document.addEventListener("turbo:before-visit", function(event) {
        const form = event.target.closest("form")
        if (form && form.enctype === "multipart/form-data") {
          event.preventDefault()
          form.submit()
        }
      })
      
      // Handle form submissions with file uploads
      document.addEventListener("submit", function(event) {
        const form = event.target
        if (form.enctype === "multipart/form-data") {
          // Disable Turbo for this form submission
          form.setAttribute("data-turbo", "false")
        }
      })
      
      // Re-enable forms after submission
      document.addEventListener("turbo:submit-end", function(event) {
        const form = event.target
        const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
        if (submitButton) {
          submitButton.disabled = false
          submitButton.textContent = submitButton.dataset.originalText || "Submit"
        }
      })
      
      // Handle form submission start
      document.addEventListener("turbo:submit-start", function(event) {
        const form = event.target
        const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
        if (submitButton) {
          submitButton.dataset.originalText = submitButton.textContent
          submitButton.disabled = true
          submitButton.textContent = "Processing..."
        }
      })
    })
  }
}

// Auto-initialize
TurboConfig.init()

// Export Turbo for other modules
export default Turbo
