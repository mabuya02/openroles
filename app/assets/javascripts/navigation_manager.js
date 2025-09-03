// Navigation and UX improvements
class NavigationManager {
  static init() {
    this.addActiveStates()
    this.addLoadingStates()
    this.addSmoothScrolling()
    this.improveFormSubmissions()
  }

  static addActiveStates() {
    // Highlight active navigation links
    const currentPath = window.location.pathname
    const navLinks = document.querySelectorAll('.nav-link')
    
    navLinks.forEach(link => {
      const href = link.getAttribute('href')
      if (href === currentPath) {
        link.classList.add('active')
      } else {
        link.classList.remove('active')
      }
    })
  }

  static addLoadingStates() {
    // Add loading states for forms
    document.addEventListener('turbo:submit-start', (event) => {
      const form = event.target
      const submitButton = form.querySelector('[type="submit"]')
      
      if (submitButton) {
        submitButton.disabled = true
        submitButton.innerHTML = '<i class="iconoir-loading me-1"></i>Loading...'
        submitButton.classList.add('btn-loading')
      }
    })

    document.addEventListener('turbo:submit-end', (event) => {
      const form = event.target
      const submitButton = form.querySelector('[type="submit"]')
      
      if (submitButton) {
        submitButton.disabled = false
        submitButton.classList.remove('btn-loading')
        // Restore original text (you might want to store this as data attribute)
        const originalText = submitButton.dataset.originalText
        if (originalText) {
          submitButton.innerHTML = originalText
        }
      }
    })
  }

  static addSmoothScrolling() {
    // Add smooth scrolling to anchor links
    document.addEventListener('click', (event) => {
      const target = event.target.closest('a[href^="#"]')
      if (target) {
        event.preventDefault()
        const element = document.querySelector(target.getAttribute('href'))
        if (element) {
          element.scrollIntoView({ 
            behavior: 'smooth',
            block: 'start'
          })
        }
      }
    })
  }

  static improveFormSubmissions() {
    // Store original button text for form submissions
    const submitButtons = document.querySelectorAll('[type="submit"]')
    submitButtons.forEach(button => {
      if (!button.dataset.originalText) {
        button.dataset.originalText = button.innerHTML
      }
    })
  }

  static showNotification(message, type = 'info') {
    // Create a simple notification system
    const notification = document.createElement('div')
    notification.className = `alert alert-${type} position-fixed top-0 end-0 m-3`
    notification.style.zIndex = '9999'
    notification.innerHTML = `
      <div class="d-flex align-items-center">
        <i class="iconoir-${type === 'success' ? 'check' : 'info-circle'} me-2"></i>
        ${message}
        <button type="button" class="btn-close ms-auto" data-bs-dismiss="alert"></button>
      </div>
    `
    
    document.body.appendChild(notification)
    
    // Auto remove after 5 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove()
      }
    }, 5000)
  }
}

// Initialize on DOM load and Turbo navigation
document.addEventListener('DOMContentLoaded', () => {
  NavigationManager.init()
})

document.addEventListener('turbo:load', () => {
  NavigationManager.init()
})

// Handle navigation clicks with visual feedback
document.addEventListener('turbo:before-visit', () => {
  // Add loading class to body
  document.body.classList.add('turbo-navigating')
})

document.addEventListener('turbo:load', () => {
  // Remove loading class
  document.body.classList.remove('turbo-navigating')
  
  // Add fade-in animation to new content
  const mainContent = document.querySelector('.page-content')
  if (mainContent) {
    mainContent.style.opacity = '0'
    mainContent.style.transform = 'translateY(10px)'
    
    requestAnimationFrame(() => {
      mainContent.style.transition = 'all 0.3s ease'
      mainContent.style.opacity = '1'
      mainContent.style.transform = 'translateY(0)'
    })
  }
})

// Export for use in other modules
window.NavigationManager = NavigationManager
