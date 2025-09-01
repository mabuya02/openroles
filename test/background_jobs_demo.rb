#!/usr/bin/env ruby
# Test background email jobs with existing user
# Run with: rails runner test/background_jobs_demo.rb
# Or with specific email: rails runner test/background_jobs_demo.rb your-email@example.com

email = ARGV[0]

puts "🚀 Background Email Jobs Demo"
puts "=" * 50

puts "\n📋 Queue Configuration:"
puts "  Adapter: #{Rails.application.config.active_job.queue_adapter}"
puts "  Environment: #{Rails.env}"

puts "\n👤 Finding existing user..."
if email.present?
  user = User.find_by(email: email)
  if user.nil?
    puts "❌ User with email #{email} not found"
    puts "Available users:"
    User.all.each { |u| puts "  - #{u.email}" }
    exit 1
  end
else
  # Use the first available user
  user = User.first
  if user.nil?
    puts "❌ No users found in database"
    exit 1
  end
end

puts "✅ Using user: #{user.first_name} #{user.last_name} (#{user.email})"

puts "\n📧 Queuing background emails..."

begin
  # 1. Welcome email
  EmailService.send_welcome_email(user)
  puts "  ✅ Welcome email queued"

  # 2. Email verification
  verification_code = user.verification_codes.create!(
    code: SecureRandom.hex(32),
    code_type: "email_verification",
    contact_method: user.email,
    expires_at: 1.hour.from_now
  )
  EmailService.send_email_verification(user, verification_code)
  puts "  ✅ Email verification queued"

  # 3. Password reset
  reset_token = user.password_reset_tokens.create!(
    token: SecureRandom.urlsafe_base64(32),
    expires_at: 1.hour.from_now,
    email: user.email,
    user_agent: "Background Job Demo",
    ip_address: "127.0.0.1"
  )
  EmailService.send_password_reset(user, reset_token)
  puts "  ✅ Password reset queued"

  puts "\n⚡ All emails queued successfully!"

  case Rails.application.config.active_job.queue_adapter.to_s
  when "async"
    puts "📤 Emails are being processed in background threads right now!"
    puts "📬 Check your inbox at: #{user.email}"
    puts "\n💡 In production with Solid Queue, these would be processed by worker processes."
  when "solid_queue"
    puts "📤 Emails will be processed by Solid Queue workers!"
    puts "📬 Make sure Solid Queue is running: bin/rails solid_queue:start"
  else
    puts "📤 Emails queued in #{Rails.application.config.active_job.queue_adapter} adapter"
  end

rescue => e
  puts "  ❌ Error: #{e.message}"
  puts "  🔍 Class: #{e.class}"
end

puts "\n" + "=" * 50
puts "🎉 Background email demo completed!"
puts "✨ User experience: Instant response, no waiting for emails!"
