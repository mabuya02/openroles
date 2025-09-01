class EmailService
  # Async email delivery methods
  def self.send_email_verification(user, verification_code)
    UserMailerJob.perform_later("email_verification", user, verification_code)
  end

  def self.send_password_reset_instructions(user, verification_code)
    UserMailerJob.perform_later("password_reset_instructions", user, verification_code)
  end

  def self.send_password_reset(user, reset_token)
    UserMailerJob.perform_later("password_reset", user, reset_token)
  end

  def self.send_password_changed_notification(user)
    UserMailerJob.perform_later("password_changed", user)
  end

  def self.send_welcome_email(user)
    UserMailerJob.perform_later("welcome_email", user)
  end

  def self.send_job_alert(user, jobs, alert)
    UserMailerJob.perform_later("job_alert", user, jobs, alert)
  end

  def self.send_application_confirmation(application)
    UserMailerJob.perform_later("application_confirmation", application)
  end

  # Immediate delivery methods (for testing or critical emails)
  def self.send_email_verification_now(user, verification_code)
    UserMailer.email_verification(user, verification_code).deliver_now
  end

  def self.send_password_reset_now(user, reset_token)
    UserMailer.password_reset(user, reset_token).deliver_now
  end

  # Bulk email methods (for newsletters, job alerts, etc.)
  def self.send_bulk_job_alerts
    BulkJobAlertsJob.perform_later
  end

  # Scheduled email methods
  def self.send_daily_job_alerts
    DailyJobAlertsJob.perform_later
  end

  def self.send_weekly_job_alerts
    WeeklyJobAlertsJob.perform_later
  end
end
