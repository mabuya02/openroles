// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails"  // Disabled Turbo to prevent blank page issues
import "controllers"
import "session_tracker"
import "alert_manager"
// import "turbo_config"  // Disabled Turbo config

// Import navigation manager for better UX
document.addEventListener('DOMContentLoaded', function() {
  console.log('Application loaded without Turbo')
  
  // Hide preloader
  const preloader = document.getElementById('preloader')
  if (preloader) {
    setTimeout(() => {
      preloader.style.display = 'none'
    }, 500)
  }
  
  // Initialize any Bootstrap components
  if (typeof bootstrap !== 'undefined') {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    tooltipTriggerList.map(function (tooltipTriggerEl) {
      return new bootstrap.Tooltip(tooltipTriggerEl)
    })
  }
})
