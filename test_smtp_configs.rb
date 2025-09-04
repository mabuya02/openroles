#!/usr/bin/env ruby
# Test Different SMTP Configurations

require_relative 'config/environment'

puts "🔧 Testing Different SMTP Configurations for Zoho..."
puts "=" * 60

# Test configuration 1: Port 587 with STARTTLS
puts "\n📧 Test 1: Port 587 with STARTTLS"
Rails.application.config.action_mailer.smtp_settings = {
  address: 'smtp.zoho.com',
  port: 587,
  domain: 'zoho.com',
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: :login,
  ssl: false,
  enable_starttls_auto: true,
  open_timeout: 10,
  read_timeout: 10
}

begin
  # Get a real alert to test with
  alert = Alert.active.first
  if alert
    jobs = alert.matching_jobs.includes(:company).limit(3).to_a
    if jobs.any?
      AlertMailer.job_alert_notification(alert, jobs).deliver_now
      puts "✅ SUCCESS: Port 587 with STARTTLS worked!"
    else
      puts "❌ No jobs found for alert"
    end
  else
    puts "❌ No active alerts found"
  end
rescue => e
  puts "❌ FAILED: #{e.message}"
end

# Test configuration 2: Port 465 with SSL (current)
puts "\n📧 Test 2: Port 465 with SSL"
Rails.application.config.action_mailer.smtp_settings = {
  address: 'smtp.zoho.com',
  port: 465,
  domain: 'zoho.com',
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: :login,
  ssl: true,
  enable_starttls_auto: false,
  open_timeout: 10,
  read_timeout: 10
}

begin
  alert = Alert.active.first
  if alert
    jobs = alert.matching_jobs.includes(:company).limit(3).to_a
    if jobs.any?
      AlertMailer.job_alert_notification(alert, jobs).deliver_now
      puts "✅ SUCCESS: Port 465 with SSL worked!"
    else
      puts "❌ No jobs found for alert"
    end
  else
    puts "❌ No active alerts found"
  end
rescue => e
  puts "❌ FAILED: #{e.message}"
end

puts "\n💡 Recommendation: Use the configuration that worked above"
