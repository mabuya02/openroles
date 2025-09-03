import { Turbo } from "@hotwired/turbo-rails"

// Initialize page components
function initializePage() {
  // Re-initialize any JavaScript components that need it
  console.log('Page initialized with Turbo')
  
  // Reinitialize Bootstrap components if needed
  if (typeof bootstrap !== 'undefined') {
    // Initialize dropdowns, tooltips, etc.
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })
  }
}

// Global Turbo configuration
export class TurboConfig {
  static init() {
    // Configure Turbo globally
    Turbo.config.drive.enabled = true
    Turbo.config.forms.mode = "on"
    
    // Add loading states and smooth transitions
    document.addEventListener("turbo:before-visit", function(event) {
      console.log('Turbo: Before visit', event.detail.url)
      // Show loading indicator
      document.body.classList.add('turbo-loading')
    })
    
    document.addEventListener("turbo:visit", function(event) {
      console.log('Turbo: Visit', event.detail.location.href)
      // Keep loading state
      document.body.classList.add('turbo-loading')
    })
    
    document.addEventListener("turbo:load", function(event) {
      console.log('Turbo: Load complete')
      // Remove loading state and initialize page
      document.body.classList.remove('turbo-loading')
      
      // Hide preloader if it's still visible
      const preloader = document.getElementById('preloader')
      if (preloader) {
        preloader.style.display = 'none'
      }
      
      initializePage()
    })
    
    document.addEventListener("turbo:render", function(event) {
      console.log('Turbo: Render complete')
      // Additional render handling if needed
    })
    
    document.addEventListener("DOMContentLoaded", function() {
      console.log('DOM Content Loaded')
      initializePage()
    })

    // Handle form submissions with file uploads
    document.addEventListener("submit", function(event) {
      const form = event.target
      if (form.enctype === "multipart/form-data") {
        console.log('Form with file upload detected, disabling Turbo')
        // Disable Turbo for this form submission
        form.setAttribute("data-turbo", "false")
      }
    })
    
    // Handle navigation errors
    document.addEventListener("turbo:before-fetch-request", function(event) {
      console.log('Turbo: Before fetch request', event.detail.url)
    })
    
    document.addEventListener("turbo:before-fetch-response", function(event) {
      console.log('Turbo: Before fetch response', event.detail.fetchResponse.status)
    })
    
    // Re-enable forms after submission
    document.addEventListener("turbo:submit-end", function(event) {
      console.log('Turbo: Submit end')
      const form = event.target
      const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
      if (submitButton) {
        submitButton.disabled = false
        submitButton.textContent = submitButton.dataset.originalText || "Submit"
      }
    })
    
    // Handle form submission start
    document.addEventListener("turbo:submit-start", function(event) {
      console.log('Turbo: Submit start')
      const form = event.target
      const submitButton = form.querySelector('input[type="submit"], button[type="submit"]')
      if (submitButton) {
        submitButton.dataset.originalText = submitButton.textContent
        submitButton.disabled = true
        submitButton.textContent = "Processing..."
      }
    })
    
    // Handle page refresh errors
    document.addEventListener("turbo:frame-missing", function(event) {
      console.log('Turbo: Frame missing', event.detail.response)
      // Navigate to the full page instead
      event.detail.visit(event.detail.response)
    })
  }
}

// Auto-initialize
TurboConfig.init()

// Export Turbo for other modules
export default Turbo
