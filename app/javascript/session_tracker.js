// Session Activity Tracker
// Tracks user activity and resets session timeout
import { application } from "controllers/application"

export class SessionTracker {
  static init() {
    document.addEventListener('DOMContentLoaded', function() {
      // Only run for authenticated users
      const userDropdown = document.querySelector('[data-controller="logout"]')
      if (!userDropdown) return

      const logoutController = application.getControllerForElementAndIdentifier(userDropdown, 'logout')
      
      // Track various user activities
      const activities = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click']
      
      let lastActivity = Date.now()
      const activityThreshold = 30000 // 30 seconds minimum between resets

      function handleActivity() {
        const now = Date.now()
        if (now - lastActivity > activityThreshold) {
          lastActivity = now
          
          // Reset the logout controller's timeout
          if (logoutController && typeof logoutController.resetTimeout === 'function') {
            logoutController.resetTimeout()
          }
        }
      }

      // Attach activity listeners
      activities.forEach(activity => {
        document.addEventListener(activity, handleActivity, true)
      })

      // Handle visibility changes (switching tabs)
      document.addEventListener('visibilitychange', function() {
        if (!document.hidden) {
          handleActivity()
        }
      })

      // Handle storage events for cross-tab logout
      window.addEventListener('storage', function(e) {
        if (e.key === 'logout-event') {
          window.location.href = '/auth/login'
        }
      })
    })
  }

  // Function to trigger logout across all tabs
  static triggerCrossTabLogout() {
    localStorage.setItem('logout-event', Date.now())
    localStorage.removeItem('logout-event')
  }
}

// Auto-initialize
SessionTracker.init()
