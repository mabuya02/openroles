require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Openroles
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # ----------------------------
    # Autoload / Eager Load Settings
    # ----------------------------
    # Ignore lib subdirectories without Ruby files (like assets or tasks)
    config.autoload_lib(ignore: %w[assets tasks])

    # Eager load lib folder in production
    config.eager_load_paths << Rails.root.join("lib")

    # ----------------------------
    # Job Queue Configuration
    # ----------------------------
    config.active_job.queue_adapter = :solid_queue

    # Configure recurring jobs for production
    # Note: recurring_schedule not supported in solid_queue 1.2.1
    # config.solid_queue.recurring_schedule = {
    #   alert_notifications: {
    #     command: "AlertNotificationJob.perform_later",
    #     schedule: "every 2 hours"
    #   },
    #   external_job_fetch: {
    #     command: "ExternalJobFetchJob.perform_later",
    #     schedule: "daily at 2am"
    #   },
    #   job_maintenance: {
    #     command: "ScheduledJobMaintenanceJob.perform_later",
    #     schedule: "daily at 3am"
    #   }
    # }

    # ----------------------------
    # Timezone Configuration
    # ----------------------------
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    # ----------------------------
    # Generators Configuration
    # ----------------------------
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid # default UUID for all tables
      g.test_framework :rspec,                     # use RSpec for testing
                       fixtures: true,           # generate fixtures
                       view_specs: false,        # skip view specs
                       helper_specs: false,      # skip helper specs
                       routing_specs: false,     # skip routing specs
                       controller_specs: true,   # generate controller specs
                       request_specs: true       # generate request specs
      g.fixture_replacement :factory_bot, dir: "spec/factories" # use FactoryBot
    end

    # Email configuration validation
    config.after_initialize do
      if Rails.env.production?
        required_email_vars = %w[
          SMTP_HOST
          SMTP_PORT
          SMTP_USERNAME
          SMTP_PASSWORD
          SMTP_DOMAIN
          FROM_EMAIL
          SUPPORT_EMAIL
          APP_HOST
        ]

        missing_vars = required_email_vars.select { |var| ENV[var].blank? }

        if missing_vars.any?
          raise "Missing required email environment variables: #{missing_vars.join(', ')}"
        end

        Rails.logger.info "Email configuration validated successfully"
      elsif Rails.env.development?
        missing_vars = %w[SMTP_HOST SMTP_USERNAME SMTP_PASSWORD].select { |var| ENV[var].blank? }
        Rails.logger.warn "Missing email environment variables: #{missing_vars.join(', ')}" if missing_vars.any?
      end
    end
  end
end
