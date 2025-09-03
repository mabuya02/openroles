# frozen_string_literal: true

# Configuration module for job fetching services
module JobFetchingConfig
  # API services configuration
  API_SERVICES = %w[jooble adzuna remotive remoteok].freeze

  # Default configuration
  DEFAULT_CONFIG = {
    tag_strategy: 'balanced',
    jobs_per_tag: 50,
    max_tags: 20,
    total_job_limit: 800,
    job_expiry_days: 30,
    cleanup_older_than_months: 3,
    batch_size: 100,
    analytics_cache_ttl: 30,
    analytics_history_limit: 50
  }.freeze

  # Schedule intervals (in hours)
  SCHEDULE_INTERVALS = {
    full_maintenance: 6,
    status_update: 2,
    daily_cleanup: 24
  }.freeze

  # Tag selection strategies
  TAG_STRATEGIES = {
    'balanced' => 'Select mix of high/medium/low performing tags',
    'performance' => 'Prioritize high-performing tags only',
    'exploration' => 'Focus on underused tags for discovery',
    'trending' => 'Use tags from trending industries',
    'comprehensive' => 'Use all available tags (up to limit)'
  }.freeze

  # Validation constants
  VALID_STRATEGIES = TAG_STRATEGIES.keys.freeze
  MAX_JOBS_PER_TAG = 200
  MAX_TOTAL_TAGS = 50
  MAX_TOTAL_JOBS = 2000

  # Cache keys
  CACHE_KEYS = {
    tag_effectiveness: 'tag_effectiveness',
    api_performance: 'api_performance_stats',
    fetch_history: 'tag_fetch_history'
  }.freeze
end
