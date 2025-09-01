class UserMailerJob < ApplicationJob
  queue_as :mailers

  retry_on StandardError, wait: 5.seconds, attempts: 3
  discard_on ArgumentError

  def perform(mailer_method:, **kwargs)
    case mailer_method.to_s
    when "email_verification"
      user = User.find(kwargs[:user_id])
      verification_code = kwargs[:verification_code]
      UserMailer.email_verification(user, verification_code).deliver_now

    when "password_reset_instructions"
      user = User.find(kwargs[:user_id])
      verification_code = kwargs[:verification_code]
      UserMailer.password_reset_instructions(user, verification_code).deliver_now

    when "password_reset"
      user = User.find(kwargs[:user_id])
      reset_token = kwargs[:reset_token]
      UserMailer.password_reset(user, reset_token).deliver_now

    when "password_changed"
      user = User.find(kwargs[:user_id])
      UserMailer.password_changed(user).deliver_now

    when "welcome_email"
      user = User.find(kwargs[:user_id])
      UserMailer.welcome_email(user).deliver_now

    when "job_alert"
      user = User.find(kwargs[:user_id])
      jobs = Job.where(id: kwargs[:job_ids])
      alert = Alert.find(kwargs[:alert_id])
      UserMailer.job_alert(user, jobs, alert).deliver_now

    when "application_confirmation"
      application = Application.find(kwargs[:application_id])
      UserMailer.application_confirmation(application).deliver_now

    else
      raise ArgumentError, "Unknown mailer method: #{mailer_method}"
    end

    Rails.logger.info "Successfully sent #{mailer_method} email"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Failed to send email - record not found: #{e.message}"
    raise # Let the job retry
  rescue => e
    Rails.logger.error "Failed to send #{mailer_method} email: #{e.message}"
    raise # Let the job retry or discard based on retry policy
  end
end
