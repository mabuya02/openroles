class AlertNotificationJob < ApplicationJob
  queue_as :default

  def perform(frequency = "daily")
    Rails.logger.info "Starting #{frequency} alert notifications"

    alerts = Alert.ready_for_notification(frequency)
    processed_count = 0
    sent_count = 0

    alerts.find_each do |alert|
      begin
        processed_count += 1
        matching_jobs = alert.matching_jobs.includes(:company, :tags).limit(20)

        if matching_jobs.any?
          # Convert to array to avoid database query issues in email template
          jobs_array = matching_jobs.to_a
          AlertMailer.job_alert_notification(alert, jobs_array).deliver_now
          alert.mark_as_notified!
          sent_count += 1

          Rails.logger.info "Sent alert to #{alert.user.email} with #{jobs_array.count} jobs"
        else
          # Still update last_notified_at to avoid sending empty notifications repeatedly
          alert.update(last_notified_at: Time.current)
          Rails.logger.debug "No matching jobs for alert ID #{alert.id}"
        end

      rescue => e
        Rails.logger.error "Failed to process alert #{alert.id}: #{e.message}"
        next
      end
    end

    Rails.logger.info "Alert notification job complete: #{processed_count} processed, #{sent_count} sent"

    # Return stats for monitoring
    {
      frequency: frequency,
      alerts_processed: processed_count,
      notifications_sent: sent_count,
      completed_at: Time.current
    }
  end
end
