class UserMailer < ApplicationMailer
  layout "mailer"
  before_action :set_common_instance_variables

  def email_verification(user, verification_code)
    @user = user
    @verification_code = verification_code
    @verification_url = auth_verify_email_url(
      user_id: @user.id,
      code: @verification_code.code
    )

    track_email_delivery(@user.email, "Verify your #{app_name} account")

    mail(
      to: @user.email,
      subject: "Verify your #{app_name} account",
      template_path: "mails",
      template_name: "email_verification"
    )
  end

  def password_reset_instructions(user, verification_code)
    @user = user
    @verification_code = verification_code
    @default_password = "OpenRoles2025!"
    @reset_url = auth_password_reset_url(
      user_id: @user.id,
      code: @verification_code.code
    )

    track_email_delivery(@user.email, "Welcome to #{app_name} - Set Your Password")

    mail(
      to: @user.email,
      subject: "Welcome to #{app_name} - Set Your Password",
      template_path: "mails",
      template_name: "password_reset_instructions"
    )
  end

  def password_reset(user, reset_token)
    @user = user
    @reset_token = reset_token
    @reset_url = auth_edit_password_url(token: @reset_token)

    track_email_delivery(@user.email, "Reset your #{app_name} password")

    mail(
      to: @user.email,
      subject: "Reset your #{app_name} password",
      template_path: "mails",
      template_name: "password_reset"
    )
  end

  def password_changed(user)
    @user = user

    track_email_delivery(@user.email, "Your #{app_name} password has been changed")

    mail(
      to: @user.email,
      subject: "Your #{app_name} password has been changed",
      template_path: "mails",
      template_name: "password_changed"
    )
  end

  # New methods for enhanced functionality
  def welcome_email(user)
    @user = user
    @login_url = "#{app_url}/login"

    track_email_delivery(@user.email, "Welcome to #{app_name}!")

    mail(
      to: @user.email,
      subject: "Welcome to #{app_name}!",
      template_path: "mails",
      template_name: "welcome_email"
    )
  end

  def job_alert(user, jobs, alert)
    @user = user
    @jobs = jobs
    @alert = alert
    @unsubscribe_url = "#{app_url}/alerts/unsubscribe?token=#{alert.unsubscribe_token}"
    @jobs_count = jobs.count

    track_email_delivery(@user.email, "#{@jobs_count} new job(s) matching your alert")

    mail(
      to: @user.email,
      subject: "#{@jobs_count} new job#{@jobs_count > 1 ? 's' : ''} matching your alert",
      template_path: "mails",
      template_name: "job_alert"
    )
  end

  def application_confirmation(application)
    @application = application
    @user = application.user
    @job = application.job
    @company = @job.company

    track_email_delivery(@user.email, "Application submitted successfully")

    mail(
      to: @user.email,
      subject: "Application submitted: #{@job.title} at #{@company.name}",
      template_path: "mails",
      template_name: "application_confirmation"
    )
  end
end
