import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="profile-form"
export default class extends Controller {
  static targets = ["submitButton"]

  connect() {
    console.log("Profile form controller connected")
    
    // Ensure multipart forms bypass Turbo
    if (this.element.enctype === "multipart/form-data") {
      this.element.setAttribute("data-turbo", "false")
    }
  }

  submit(event) {
    this.disableSubmitButton()
    
    // Let the form submit normally
    // Re-enable button after a delay in case of errors
    setTimeout(() => {
      this.enableSubmitButton()
    }, 5000)
  }

  disableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.value = "Updating..."
    }
  }

  enableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.value = "Update Profile"
    }
  }
}
