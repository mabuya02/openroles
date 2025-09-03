# frozen_string_literal: true

# Service to manage job lifecycle and cleanup closed/expired jobs
class JobLifecycleService
  include JobFetchingConfig

  class << self
    # Update job statuses and mark closed/expired jobs
    def update_job_statuses
      Rails.logger.info "Starting job status update process..."
      
      stats = initialize_stats
      stats[:marked_expired] = mark_expired_jobs
      
      update_recent_jobs_status(stats)
      log_completion(stats)
      
      stats
    end

    # Clean up old closed jobs (optional - run less frequently)
    def cleanup_old_jobs(older_than: DEFAULT_CONFIG[:cleanup_older_than_months].months)
      cleanup_date = older_than.ago
      
      old_jobs = Job.closed_or_expired.where('updated_at < ?', cleanup_date)
      count = old_jobs.count
      
      return 0 if count.zero?
      
      Rails.logger.info "Cleaning up #{count} old jobs older than #{cleanup_date}"
      old_jobs.destroy_all
      count
    end

    private

    def initialize_stats
      {
        marked_expired: 0,
        marked_closed: 0,
        verified_active: 0,
        errors: 0
      }
    end

    def update_recent_jobs_status(stats)
      recent_jobs = Job.published
                      .recently_updated
                      .includes(:company)
                      .limit(DEFAULT_CONFIG[:batch_size])

      recent_jobs.find_each(batch_size: 50) do |job|
        update_job_status(job, stats)
      end
    end

    def update_job_status(job, stats)
      if job_still_available?(job)
        stats[:verified_active] += 1
      else
        job.update!(status: JobStatus::CLOSED)
        stats[:marked_closed] += 1
        Rails.logger.info "Marked job as closed: #{job.title} at #{job.company.name}"
      end
    rescue StandardError => e
      Rails.logger.error "Error verifying job #{job.id}: #{e.message}"
      stats[:errors] += 1
    end

    def log_completion(stats)
      Rails.logger.info "Job status update completed: #{stats}"
    end

    def mark_expired_jobs
      expired_cutoff = DEFAULT_CONFIG[:job_expiry_days].days.ago
      
      expired_jobs = Job.published.where('created_at < ?', expired_cutoff)
      count = expired_jobs.count
      
      return 0 if count.zero?
      
      Rails.logger.info "Marking #{count} jobs as expired (older than #{expired_cutoff})"
      expired_jobs.update_all(status: JobStatus::EXPIRED)
      count
    end

    def job_still_available?(job)
      return false unless job.source_url.present?
      
      # Basic availability check - could be enhanced with API calls
      response = Net::HTTP.get_response(URI(job.source_url))
      ![404, 410, 500].include?(response.code.to_i)
    rescue Net::TimeoutError, SocketError, StandardError
      # If we can't check, assume it's still available to avoid false positives
      true
    end
  end
end
