#!/usr/bin/env ruby
# Test Alert Email Script

# Add Rails environment
require_relative 'config/environment'

puts "🔍 Testing Alert System..."
puts "=" * 50

# Check if we have any alerts
alerts = Alert.where(status: AlertStatus::ACTIVE)
puts "Active Alerts: #{alerts.count}"

if alerts.empty?
  puts "❌ No active alerts found!"
  exit
end

# Get the first active alert
alert = alerts.first
puts "Testing alert: #{alert.id}"
puts "User: #{alert.user.email}"
puts "Natural Query: #{alert.criteria['natural_query']}"

# Get matching jobs
matching_jobs = alert.matching_jobs.includes(:company).limit(10)
puts "Matching Jobs Found: #{matching_jobs.count}"

if matching_jobs.empty?
  puts "❌ No matching jobs found for this alert!"

  # Let's check what jobs are available
  total_jobs = Job.published.count
  puts "Total published jobs in database: #{total_jobs}"

  if total_jobs > 0
    sample_job = Job.published.first
    puts "Sample job: #{sample_job.title} at #{sample_job.company.name}"
  end
else
  puts "✅ Found #{matching_jobs.count} matching jobs:"
  matching_jobs.limit(3).each_with_index do |job, index|
    puts "  #{index + 1}. #{job.title} at #{job.company.name}"
  end

  # Now try to send the email
  puts "\n📧 Sending test email..."
  begin
    # Convert to array to avoid database query issues in email template
    jobs_array = matching_jobs.includes(:company).to_a
    AlertMailer.job_alert_notification(alert, jobs_array).deliver_now
    puts "✅ Email sent successfully to #{alert.user.email}"
  rescue => e
    puts "❌ Failed to send email: #{e.message}"
    puts "Error details: #{e.backtrace.first(5).join("\n")}"
  end
end

puts "\n📊 Email Configuration:"
puts "SMTP Host: #{ENV['SMTP_HOST']}"
puts "SMTP Port: #{ENV['SMTP_PORT']}"
puts "From Email: #{ENV['FROM_EMAIL']}"
puts "SMTP Authentication: #{ENV['SMTP_AUTHENTICATION']}"
