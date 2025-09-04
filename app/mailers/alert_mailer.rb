class AlertMailer < ApplicationMailer
  # Use the same from address as ApplicationMailer (from environment variable)
  # default from: -> { ENV.fetch("FROM_EMAIL", "noreply@openroles.com") }

  def job_alert_notification(alert, matching_jobs)
    @alert = alert
    @user = alert.user
    @matching_jobs = matching_jobs
    @unsubscribe_url = unsubscribe_alert_url(@alert.unsubscribe_token)
    @alert_url = alert_url(@alert)

    # Determine email subject based on alert criteria
    subject = build_email_subject

    mail(
      to: @user.email,
      subject: subject,
      template_name: "job_alert_notification"
    )
  end

  def welcome_alert(alert)
    @alert = alert
    @user = alert.user
    @unsubscribe_url = unsubscribe_alert_url(@alert.unsubscribe_token)
    @alert_url = alert_url(@alert)

    mail(
      to: @user.email,
      subject: "Your job alert is now active!",
      template_name: "welcome_alert"
    )
  end

  private

  def build_email_subject
    job_count = @matching_jobs.count
    frequency = @alert.frequency

    if @alert.criteria.present? && @alert.criteria["natural_query"].present?
      query_snippet = @alert.criteria["natural_query"].truncate(30)
      "#{job_count} new #{'job'.pluralize(job_count)} for \"#{query_snippet}\""
    else
      "#{job_count} new #{'job'.pluralize(job_count)} from your #{frequency} alert"
    end
  end
end
