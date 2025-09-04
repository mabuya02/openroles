# Preview all emails at http://localhost:3000/rails/mailers/alert_mailer_mailer
class AlertMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/alert_mailer_mailer/job_alert_notification
  def job_alert_notification
    AlertMailer.job_alert_notification
  end

end
