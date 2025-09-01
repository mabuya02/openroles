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
    config.active_job.queue_adapter = :async

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
  end
end
