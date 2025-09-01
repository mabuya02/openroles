#!/usr/bin/env ruby
# Test email configuration
# Run with: rails runner test/email_config_test.rb

puts "🔧 Testing Email Configuration"
puts "=" * 50

# Check environment variables
puts "\n📋 Environment Variables:"
email_vars = %w[SMTP_HOST SMTP_PORT SMTP_USERNAME FROM_EMAIL SUPPORT_EMAIL APP_HOST]
email_vars.each do |var|
  value = ENV[var]
  puts "  #{var}: #{value ? '✅' : '❌'} #{value ? value : 'Not set'}"
end

# Check SMTP settings
puts "\n⚙️  SMTP Configuration:"
smtp_settings = Rails.application.config.action_mailer.smtp_settings
smtp_settings.each do |key, value|
  puts "  #{key}: #{value}"
end

# Test creating a mailer (without sending)
puts "\n📧 Mailer Test:"
begin
  require "ostruct"

  user = OpenStruct.new(
    email: "test@example.com",
    first_name: "Test",
    last_name: "User"
  )

  mailer = UserMailer.welcome_email(user)
  puts "  ✅ Mailer object created successfully"
  puts "  📤 From: #{mailer.from.first}"
  puts "  📬 To: #{mailer.to.first}"
  puts "  📝 Subject: #{mailer.subject}"

  # Test if we can generate the email without sending
  message = mailer.message
  puts "  ✅ Email message generated successfully"
  puts "  📄 Body preview: #{message.body.to_s[0..100]}..."

rescue => e
  puts "  ❌ Error: #{e.message}"
  puts "  🔍 Backtrace: #{e.backtrace.first(3).join(', ')}"
end

puts "\n" + "=" * 50
puts "🎉 Email configuration test completed!"

if ENV["SMTP_USERNAME"].present? && ENV["SMTP_PASSWORD"].present?
  puts "✅ Configuration looks good! Ready to send emails."
  puts "💡 To test actual email sending, update the test above to call .deliver_now"
else
  puts "⚠️  Add your SMTP credentials to .env file to enable email sending"
end
