# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Custom JavaScript files
pin "session_tracker", to: "session_tracker.js"
pin "alert_manager", to: "alert_manager.js"
pin "turbo_config", to: "turbo_config.js"
