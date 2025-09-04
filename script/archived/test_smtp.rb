#!/usr/bin/env ruby
# Test SMTP Configuration

require_relative 'config/environment'

puts "🔧 Testing SMTP Configuration..."
puts "=" * 50

config = Rails.application.config.action_mailer.smtp_settings
puts "SMTP Settings:"
config.each do |key, value|
  puts "  #{key}: #{value}"
end

puts "\n📧 Testing simple email send..."
begin
  # Find a user to send test email to
  user = User.first
  if user.nil?
    puts "❌ No users found in database"
    exit
  end

  # Create a test alert
  alert = Alert.new(
    user: user,
    frequency: 'daily',
    status: AlertStatus::ACTIVE,
    criteria: { "natural_query" => "Test alert" },
    unsubscribe_token: SecureRandom.hex(32)
  )

  # Create simple test email using AlertMailer welcome method
  puts "Sending welcome alert email to #{user.email}..."
  AlertMailer.welcome_alert(alert).deliver_now

  puts "✅ Test email sent successfully!"
rescue => e
  puts "❌ SMTP test failed: #{e.message}"
  puts "Error class: #{e.class}"

  if e.message.include?("end of file")
    puts "\n💡 Suggestion: This usually indicates SSL/TLS configuration issues."
    puts "   For Zoho SMTP on port 465, you need SSL=true and STARTTLS=false"
  end
end
