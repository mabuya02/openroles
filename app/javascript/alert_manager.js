// Alert Manager for handling flash messages and notifications
export class AlertManager {
  static init() {
    // Auto-dismiss alerts after 5 seconds
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(alert => {
      setTimeout(() => {
        const closeButton = alert.querySelector('.btn-close');
        if (closeButton) {
          closeButton.click();
        }
      }, 5000);
    });
  }

  static showAlert(message, type = 'info') {
    // Create and show a new alert
    const alertHTML = `
      <div class="alert alert-${type} alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    `;
    
    // Find or create alert container
    let container = document.querySelector('.alert-container');
    if (!container) {
      container = document.createElement('div');
      container.className = 'alert-container';
      document.body.insertBefore(container, document.body.firstChild);
    }
    
    container.insertAdjacentHTML('beforeend', alertHTML);
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  AlertManager.init();
});

// Auto-initialize
AlertManager.init();