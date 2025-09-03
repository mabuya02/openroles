# frozen_string_literal: true

# Background job to fetch jobs from external APIs
class JobFetchJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(sources: nil, keywords: nil, location: nil, limit: 50)
    Rails.logger.info "Starting job fetch from APIs: #{sources || 'all'}"

    job_fetcher = JobFetcherService.new(
      sources: sources || JobFetcherService::API_SERVICES.keys,
      keywords: keywords,
      location: location,
      limit: limit
    )

    results = job_fetcher.fetch_all

    # Log summary
    log_results(results)

    # You could also send notifications or update metrics here
    notify_completion(results) if should_notify?(results)

    results
  rescue StandardError => e
    Rails.logger.error "JobFetchJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Re-raise to trigger retry mechanism
    raise e
  end

  private

  def log_results(results)
    success_count = results[:success]&.size || 0
    error_count = results[:errors]&.size || 0

    total_jobs = results[:success]&.sum { |r| r[:processed] || 0 } || 0

    Rails.logger.info "Job fetch completed: #{success_count} sources successful, #{error_count} failed, #{total_jobs} jobs processed"

    results[:errors]&.each do |error|
      Rails.logger.warn "API Error for #{error[:source]}: #{error[:error]}"
    end
  end

  def should_notify?(results)
    # Add your notification logic here
    # For example, notify if there are errors or if many jobs were processed
    error_count = results[:errors]&.size || 0
    success_count = results[:success]&.size || 0

    error_count > 0 || success_count > 2
  end

  def notify_completion(results)
    # You could send email notifications, Slack messages, etc.
    Rails.logger.info "Job fetch notification would be sent here"

    # Example: Send to admin email
    # AdminMailer.job_fetch_summary(results).deliver_later
  end
end
