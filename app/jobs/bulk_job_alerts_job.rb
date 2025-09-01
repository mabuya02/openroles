class BulkJobAlertsJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 15.minutes, attempts: 2

  def perform
    Rails.logger.info "Starting bulk job alerts processing..."

    # Process daily alerts
    DailyJobAlertsJob.perform_now

    # Process weekly alerts (only on specific days)
    if should_process_weekly_alerts?
      WeeklyJobAlertsJob.perform_now
    end

    # Process monthly alerts (only on specific dates)
    if should_process_monthly_alerts?
      MonthlyJobAlertsJob.perform_now
    end

    Rails.logger.info "Bulk job alerts processing completed"
  end

  private

  def should_process_weekly_alerts?
    # Run weekly alerts on Mondays
    Date.current.monday?
  end

  def should_process_monthly_alerts?
    # Run monthly alerts on the 1st of each month
    Date.current.day == 1
  end
end
