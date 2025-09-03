# frozen_string_literal: true

# Initializer for scheduled job system
Rails.application.configure do
  # Initialize the scheduled job system after Rails boots
  config.after_initialize do
    # Only set up scheduling in production or when explicitly enabled
    if Rails.env.production? || ENV["ENABLE_SCHEDULED_JOBS"] == "true"
      # Set up the initial schedule
      Rails.logger.info "Setting up scheduled job maintenance system..."

      # Schedule the first maintenance cycle to start in 1 hour
      ScheduledJobMaintenanceJob.set(wait: 1.hour).perform_later(operation: :full_maintenance)

      Rails.logger.info "Scheduled job maintenance system initialized"
    else
      Rails.logger.info "Scheduled jobs disabled (not in production). Set ENABLE_SCHEDULED_JOBS=true to enable."
    end
  end
end
