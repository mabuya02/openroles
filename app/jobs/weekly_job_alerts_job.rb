class WeeklyJobAlertsJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 30.minutes, attempts: 3

  def perform
    Rails.logger.info "Starting weekly job alerts processing..."

    # Find all alerts that are ready for weekly notifications
    alerts = Alert.ready_for_notification("weekly")
    processed = 0

    alerts.find_each do |alert|
      begin
        matching_jobs = alert.matching_jobs

        if matching_jobs.any?
          UserMailerJob.perform_later("job_alert", alert.user, matching_jobs.to_a, alert)
          alert.mark_as_notified!
          processed += 1
        end
      rescue => e
        Rails.logger.error "Failed to process weekly alert #{alert.id}: #{e.message}"
      end
    end

    Rails.logger.info "Weekly job alerts completed: #{processed} alerts processed"
  end
end
