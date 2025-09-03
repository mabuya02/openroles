# frozen_string_literal: true

# Background job for tag-based job fetching
class TagBasedJobFetchJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(
    strategy: :balanced,
    sources: [ :jooble, :adzuna, :remotive, :remoteok ],
    jobs_per_tag: 15,
    max_tags: 50,
    total_job_limit: 1000,
    location: nil
  )
    Rails.logger.info "Starting scheduled tag-based job fetch with strategy: #{strategy}"

    fetcher = TagBasedJobFetcherService.new(
      sources: sources,
      tag_strategy: strategy,
      location: location,
      jobs_per_tag: jobs_per_tag,
      max_tags: max_tags,
      total_job_limit: total_job_limit
    )

    results = fetcher.fetch_jobs_by_tags

    # Log summary for monitoring
    log_job_summary(results[:summary])

    # Optionally send notifications about the job fetch
    notify_job_fetch_completion(results[:summary]) if should_notify?(results[:summary])

    results[:summary]
  end

  # Specialized methods for different use cases
  def self.fetch_diverse_jobs(job_limit: 500)
    perform_later(
      strategy: :diverse,
      jobs_per_tag: 10,
      max_tags: 50,
      total_job_limit: job_limit
    )
  end

  def self.fetch_popular_tag_jobs(job_limit: 300)
    perform_later(
      strategy: :popular,
      jobs_per_tag: 20,
      max_tags: 15,
      total_job_limit: job_limit
    )
  end

  def self.fetch_technology_jobs(job_limit: 400)
    perform_later(
      strategy: :technology_focused,
      jobs_per_tag: 25,
      max_tags: 20,
      total_job_limit: job_limit
    )
  end

  def self.help_underrepresented_tags(job_limit: 200)
    # Use the service directly for this specialized case
    fetcher = TagBasedJobFetcherService.new(
      jobs_per_tag: 10,
      max_tags: 30,
      total_job_limit: job_limit
    )

    fetcher.fetch_for_underrepresented_tags
  end

  private

  def log_job_summary(summary)
    Rails.logger.info "Job fetch completed - Strategy: #{summary[:strategy_used]}, " \
                     "Fetched: #{summary[:total_jobs_fetched]}, " \
                     "Created: #{summary[:new_jobs_created]}, " \
                     "Tags: #{summary[:tags_attempted]}, " \
                     "Errors: #{summary[:errors_count]}"
  end

  def should_notify?(summary)
    # Notify if we created a significant number of jobs or if there were many errors
    summary[:new_jobs_created] > 50 || summary[:errors_count] > 5
  end

  def notify_job_fetch_completion(summary)
    # Could integrate with Slack, email, or other notification systems
    Rails.logger.warn "Job fetch notification: #{summary[:new_jobs_created]} new jobs created, #{summary[:errors_count]} errors"

    # Example: Could send to admin email, Slack webhook, etc.
    # AdminMailer.job_fetch_summary(summary).deliver_now
  end
end
