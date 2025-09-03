# frozen_string_literal: true

# Background job for scheduled job fetching and maintenance
class ScheduledJobMaintenanceJob < ApplicationJob
  queue_as :default

  # Perform regular maintenance and fetching
  def perform(operation: :full_maintenance)
    Rails.logger.info "Starting scheduled job maintenance: #{operation}"

    case operation.to_sym
    when :full_maintenance
      perform_full_maintenance
    when :fetch_only
      perform_job_fetching_only
    when :status_update_only
      perform_status_updates_only
    when :cleanup_only
      perform_cleanup_only
    else
      raise ArgumentError, "Unknown operation: #{operation}"
    end

    Rails.logger.info "Completed scheduled job maintenance: #{operation}"
  end

  # Schedule regular maintenance (call this from initializer or whenever gem)
  def self.schedule_regular_maintenance
    # Main fetch and update cycle - every 6 hours
    ScheduledJobMaintenanceJob.set(wait: 6.hours).perform_later(operation: :full_maintenance)

    # Status updates only - every 2 hours
    ScheduledJobMaintenanceJob.set(wait: 2.hours).perform_later(operation: :status_update_only)

    # Cleanup old jobs - daily at 2 AM
    ScheduledJobMaintenanceJob.set(wait: 1.day).perform_later(operation: :cleanup_only)

    Rails.logger.info "Scheduled regular job maintenance tasks"
  end

  # Emergency fetch when job count is low
  def self.emergency_fetch_if_needed
    recent_jobs_count = Job.published.where(created_at: 24.hours.ago..Time.current).count

    if recent_jobs_count < 20 # Threshold for emergency fetch
      Rails.logger.warn "Low job count detected (#{recent_jobs_count}), triggering emergency fetch"
      ScheduledJobMaintenanceJob.perform_later(operation: :fetch_only)
    end
  end

  private

  def perform_full_maintenance
    Rails.logger.info "=== FULL MAINTENANCE CYCLE START ==="

    # Step 1: Update existing job statuses
    status_stats = JobLifecycleService.update_job_statuses
    Rails.logger.info "Status update stats: #{status_stats}"

    # Step 2: Fetch new jobs using tag-based system
    fetch_stats = perform_job_fetching
    Rails.logger.info "Job fetching stats: #{fetch_stats}"

    # Step 3: Basic cleanup if needed
    if should_perform_cleanup?
      cleanup_stats = JobLifecycleService.cleanup_old_jobs(older_than: 2.months)
      Rails.logger.info "Cleanup stats: removed #{cleanup_stats} old jobs"
    end

    # Step 4: Generate summary report
    generate_maintenance_report(status_stats, fetch_stats)

    Rails.logger.info "=== FULL MAINTENANCE CYCLE COMPLETE ==="
  end

  def perform_job_fetching_only
    Rails.logger.info "Performing job fetching cycle..."

    # Use different strategies based on time of day or current job count
    strategy = determine_fetching_strategy

    case strategy
    when :diverse
      TagBasedJobFetchJob.fetch_diverse_jobs(job_limit: 300)
    when :technology_focused
      TagBasedJobFetchJob.fetch_technology_jobs(job_limit: 200)
    when :underrepresented_help
      TagBasedJobFetchJob.help_underrepresented_tags(job_limit: 150)
    when :popular
      TagBasedJobFetchJob.fetch_popular_tag_jobs(job_limit: 250)
    end
  end

  def perform_status_updates_only
    Rails.logger.info "Performing status updates only..."
    JobLifecycleService.update_job_statuses
  end

  def perform_cleanup_only
    Rails.logger.info "Performing cleanup only..."
    JobLifecycleService.cleanup_old_jobs(older_than: 3.months)
  end

  def determine_fetching_strategy
    current_hour = Time.current.hour
    recent_jobs = Job.published.where(created_at: 24.hours.ago..Time.current).count

    # Emergency: very low job count
    return :diverse if recent_jobs < 10

    # Night time (0-6 AM): Help underrepresented tags
    return :underrepresented_help if current_hour.between?(0, 6)

    # Morning (6-12 PM): Technology focus for business hours
    return :technology_focused if current_hour.between?(6, 12)

    # Afternoon (12-18 PM): Diverse fetching
    return :diverse if current_hour.between?(12, 18)

    # Evening (18-24 PM): Popular tags
    :popular
  end

  def should_perform_cleanup?
    # Only cleanup on weekends or if we have too many closed jobs
    Time.current.saturday? || Time.current.sunday? ||
      Job.where(status: [ JobStatus::CLOSED, JobStatus::EXPIRED ]).count > 1000
  end

  def perform_job_fetching
    begin
      # Get current job count for comparison
      initial_count = Job.count

      # Perform the fetch
      perform_job_fetching_only

      # Calculate results
      final_count = Job.count
      new_jobs = final_count - initial_count

      {
        success: true,
        new_jobs_added: new_jobs,
        total_jobs_now: final_count,
        strategy_used: determine_fetching_strategy
      }
    rescue => e
      Rails.logger.error "Job fetching failed: #{e.message}"
      { success: false, error: e.message }
    end
  end

  def generate_maintenance_report(status_stats, fetch_stats)
    report = {
      timestamp: Time.current,
      status_updates: status_stats,
      job_fetching: fetch_stats,
      current_totals: {
        total_jobs: Job.count,
        active_jobs: Job.published.count,
        companies: Company.count,
        active_companies: Company.active.count
      }
    }

    Rails.logger.info "=== MAINTENANCE REPORT ==="
    Rails.logger.info report.to_json
    Rails.logger.info "=========================="

    # You could also store this report in cache or send notifications
    Rails.cache.write("last_maintenance_report", report, expires_in: 7.days)

    report
  end
end
