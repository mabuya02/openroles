#!/usr/bin/env ruby
# Test background email jobs
# Run with: rails runner test/background_jobs_test.rb

puts "🚀 Testing Background Email Jobs"
puts "=" * 50

# Test 1: Check Active Job configuration
puts "\n📋 Active Job Configuration:"
puts "  Queue Adapter: #{Rails.application.config.active_job.queue_adapter}"
puts "  Environment: #{Rails.env}"

# Test 2: Create test user
puts "\n👤 Creating test user..."
user = User.new(
  email: "test@example.com",
  first_name: "Test",
  last_name: "User"
)

# Test 3: Queue background jobs
puts "\n📧 Queuing background email jobs..."

begin
  # Test queuing different email types
  EmailService.send_welcome_email(user)
  puts "  ✅ Welcome email queued"

  # Test with verification code
  verification_code = OpenStruct.new(
    code: SecureRandom.hex(32),
    expires_at: 1.hour.from_now
  )
  EmailService.send_email_verification(user, verification_code)
  puts "  ✅ Email verification queued"

  # Check queue status
  if Rails.application.config.active_job.queue_adapter == :async
    puts "\n⚡ Using async adapter - jobs will process immediately in background threads"
  elsif Rails.application.config.active_job.queue_adapter == :test
    puts "\n🧪 Using test adapter - jobs are stored in memory for testing"
    puts "  Enqueued jobs: #{ActiveJob::Base.queue_adapter.enqueued_jobs.count}"
  else
    puts "\n💾 Using persistent queue adapter - jobs are stored in database"
  end

rescue => e
  puts "  ❌ Error queuing jobs: #{e.message}"
  puts "  🔍 Backtrace: #{e.backtrace.first(3).join(', ')}"
end

# Test 4: Check job classes exist
puts "\n🔧 Checking job classes:"
job_classes = %w[UserMailerJob DailyJobAlertsJob WeeklyJobAlertsJob BulkJobAlertsJob]
job_classes.each do |job_class|
  begin
    job_class.constantize
    puts "  ✅ #{job_class} exists"
  rescue NameError
    puts "  ❌ #{job_class} missing"
  end
end

# Test 5: Check EmailService methods
puts "\n📬 Checking EmailService methods:"
email_methods = %w[
  send_welcome_email
  send_email_verification
  send_password_reset
  send_job_alert
]
email_methods.each do |method|
  if EmailService.respond_to?(method)
    puts "  ✅ EmailService.#{method} available"
  else
    puts "  ❌ EmailService.#{method} missing"
  end
end

puts "\n" + "=" * 50
puts "🎉 Background jobs test completed!"

case Rails.application.config.active_job.queue_adapter.to_s
when "async"
  puts "✨ Your emails are now being sent in background threads!"
  puts "💡 Users won't wait for email delivery to complete their actions."
when "solid_queue"
  puts "🏗️  Your emails will be processed by Solid Queue workers!"
  puts "💡 Make sure to run: 'bin/rails solid_queue:start' in production."
when "test"
  puts "🧪 Test mode - jobs are queued but not processed automatically."
  puts "💡 Use 'perform_enqueued_jobs' in your tests to execute them."
else
  puts "⚙️  Custom queue adapter configured: #{Rails.application.config.active_job.queue_adapter}"
end
