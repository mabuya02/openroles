#!/usr/bin/env ruby
# Send a real test email
# Run with: rails runner test/send_test_email.rb your-email@example.com

email = ARGV[0]

if email.blank?
  puts "❌ Please provide an email address"
  puts "Usage: rails runner test/send_test_email.rb your-email@example.com"
  exit 1
end

puts "📧 Sending test email to: #{email}"

begin
  user = OpenStruct.new(
    email: email,
    first_name: "Test",
    last_name: "User"
  )

  UserMailer.welcome_email(user).deliver_now
  puts "✅ Test email sent successfully!"
  puts "📬 Check your inbox at #{email}"

rescue => e
  puts "❌ Failed to send email: #{e.message}"
  puts "🔍 Error details: #{e.class}: #{e.message}"
  if e.backtrace.present?
    puts "📍 Location: #{e.backtrace.first}"
  end
end
