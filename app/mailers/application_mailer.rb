class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("FROM_EMAIL", "noreply@openroles.com") }
  layout "mailer"

  # Add common helper methods
  def support_email
    ENV.fetch("SUPPORT_EMAIL", "support@openroles.com")
  end

  def app_name
    ENV.fetch("APP_NAME", "OpenRoles")
  end

  def app_url
    "#{ENV.fetch('APP_PROTOCOL', 'https')}://#{ENV.fetch('APP_HOST', 'openroles.com')}"
  end

  # Error handling wrapper
  def safe_deliver(mail_method, *args)
    send(mail_method, *args).deliver_now
  rescue => e
    Rails.logger.error "Failed to send email: #{e.message}"
    raise e if Rails.env.production?
  end

  protected

  def set_common_instance_variables
    @app_name = app_name
    @app_url = app_url
    @support_email = support_email
  end

  def track_email_delivery(recipient, subject)
    Rails.logger.info "Email sent to: #{recipient}, Subject: #{subject}"
  end
end
